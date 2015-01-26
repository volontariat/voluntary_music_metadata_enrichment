# -*- encoding : utf-8 -*-
class MusicRelease < ActiveRecord::Base
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :user
  
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'release_id', dependent: :destroy
  
  def self.by_artist_and_name(artist_name, name)
    # TODO: monitor if there are artists with multiple releases with the same name
    where(
      "LOWER(artist_name) = :artist_name AND LOWER(name) = :name", 
      artist_name: artist_name.downcase.strip, name: name.downcase.strip
    )
  end
  
  scope :artist_and_name_like, ->(artist_name, name) do
    table = MusicRelease.arel_table
    where(table[:artist_name].matches("%#{artist_name}%").and(table[:name].matches("%#{name}%")))
  end
  
  scope :released_in_year, ->(year) do
    where("released_at >= :from AND released_at <= :to", from: Time.local(year,1,1,0,0,0), to: Time.local(year,12,31,23,59,59))
  end
  
  scope :for_year_in_review, ->(year_in_review) do
    released_in_year(year_in_review.year).where('music_releases.id NOT IN(?)', year_in_review.releases.map(&:release_id))
  end
  
  validates :artist_id, presence: true
  validates :name, presence: true
  validates :mbid, uniqueness: true, allow_blank: true, length: { is: 36 }
  validate :future_release_date_format
  
  before_save :set_artist_name
  after_update :sync_tracks
  after_update :sync_year_in_review_music_releases
  
  attr_accessible :mbid, :artist_id, :artist_name, :name, :future_release_date, :released_at, :listeners, :plays
  
  attr_accessor :releases
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |release, transition|
      releases = if release.releases.nil?
        MusicBrainz::ReleaseGroup.find(release.groups.select{|r| r[:title] == release.name }.first[:id]).releases
      else
        release.releases
      end
      
      releases = release.prefered_releases(releases)
     
      if releases.select{|r| r.media.map(&:format).include?('CD') }.any?
        releases = releases.select{|r| r.media.map(&:format).include?('CD') }
      end
      
      releases = release.earliest_release(releases)
      musicbrainz_release, dvd_recording_mbids = release.release_with_highest_tracks_count(releases)
      release.update_attributes(mbid: musicbrainz_release.id, released_at: musicbrainz_release.date)
      
      begin
        lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
        lastfm_album = lastfm.album.get_info(artist: release.artist_name, album: release.name)
        release.update_attributes(listeners: lastfm_album['listeners'], plays: lastfm_album['playcount'])
      rescue Lastfm::ApiError
        # rescue from album not found
      end
      
      #musicbrainz_release = MusicBrainz::Release.find(mbid, [:recordings])
      recordings = nil
      
      3.times do
        recordings = MusicBrainz::Recording.by_release_id(musicbrainz_release.id)
        
        break if recordings.respond_to? :each
        
        sleep 60
      end
      
      first_track_nr_of_disc = release.get_first_track_nr_of_disc(recordings)
      
      recordings.each do |musicbrainz_recording|
        next if dvd_recording_mbids.include? musicbrainz_recording.id
        
        track_name = MusicTrack.format_name(musicbrainz_recording.title)
        
        if musicbrainz_recording.disambiguation.present? && !track_name.match('\(') && !musicbrainz_recording.disambiguation.match(/Album version|Single version/i)
          # example: http://musicbrainz.org/release/e3f92095-5466-3a96-8dc3-f5c86c35a954
          track_name = "#{track_name} (#{musicbrainz_recording.disambiguation})"
        end
        
        medium = musicbrainz_recording.releases.select{|r2| r2.id == musicbrainz_release.id}.first.media.first
        nr = first_track_nr_of_disc[medium.position] + medium.tracks.first.number.to_i - 1
        
        track = nil
        
        begin
          track = MusicTrack.create(
            mbid: musicbrainz_recording.id, artist_id: release.artist_id, artist_name: release.artist_name, 
            release_id: release.id, release_name: release.name, nr: nr, name: track_name, 
            duration: musicbrainz_recording.length
          )
        rescue ActiveRecord::RecordNotUnique
        end
        
        # no bang because of releases like the following which includes the same track multiple times: http://musicbrainz.org/release/2b18f9eb-b171-4fd6-ab1f-9801c4adc992
        if track.try(:id)
          track.import_metadata
        end
      end
    end
  end
  
  def self.format_lastfm_name(name)
    return name if name.nil?
    
    name.gsub(/\(Deluxe Edition\)|\(Deluxe\)|\(Deluxe Version\)|\(Deluxe Package\)|\(Bonus Version\)|\(Legacy Edition\)|\(Standard Version\)|\(Remastered Version\)|\(Remastered\)/i, '').strip
  end
  
  def groups
    musicbrainz_release_groups = MusicBrainz::ReleaseGroup.search(artist.mbid, name, extra_query: 'AND (type:album OR type:ep)')
    musicbrainz_release_groups.select{|rg| rg[:releases].select{|r| r[:status] == 'Official'}.any? && (rg[:secondary_types].nil? || rg[:secondary_types].select{|st| ['Audiobook', 'Compilation', 'Live', 'Remix'].include?(st)}.none?) && rg[:artists].length == 1 }
  end
 
  def groups_without_limitation
    MusicBrainz::ReleaseGroup.search(artist.mbid, name)
  end
   
  def formatted_released_at_or_future_release_date 
    if future_release_date.present? then future_release_date
    elsif released_at.present? then released_at.strftime('%d.%m.%Y')
    else nil
    end
  end
  
  def prefered_releases(working_releases)
    list = []
    
    working_releases.each do |working_musicbrainz_release|
      next unless working_musicbrainz_release.status == 'Official'
      
      next if working_musicbrainz_release.media.map(&:format).select{|f| !['DVD-Video', 'DVD'].include?(f) }.none?
      
      list << working_musicbrainz_release
    end    
    
    list
  end
  
  def earliest_release(working_releases)
    earliest_release_date, filtered_releases = nil, []
    
    working_releases.each do |working_musicbrainz_release|
      if working_musicbrainz_release.date != nil && (earliest_release_date == nil || working_musicbrainz_release.date < earliest_release_date)
        filtered_releases.clear
        filtered_releases << working_musicbrainz_release
        earliest_release_date = working_musicbrainz_release.date
      elsif working_musicbrainz_release.date == earliest_release_date
        filtered_releases << working_musicbrainz_release
      end
    end
    
    filtered_releases
  end
   
  def release_with_highest_tracks_count(working_releases)
    musicbrainz_release, highest_tracks_count = nil, 0
    
    working_releases.each do |working_musicbrainz_release|
      working_tracks_count = working_musicbrainz_release.media.select{|m| !['DVD-Video', 'DVD'].include?(m.format) }.map{|m| m.tracks.total_count }.inject{|sum,x| sum + x }
      
      if working_tracks_count > highest_tracks_count
        highest_tracks_count = working_tracks_count
        musicbrainz_release = working_musicbrainz_release
      end
    end
    
    dvd_recording_mbids = musicbrainz_release.media.select{|m| ['DVD-Video', 'DVD'].include?(m.format) }.map{|m| m.tracks.map{|t| t.recording.id }}.flatten.inspect
 
    [musicbrainz_release, dvd_recording_mbids]
  end 
   
  def get_first_track_nr_of_disc(recordings)
    tracks_count_by_disc = {}

    recordings.each do |musicbrainz_recording|
      medium = musicbrainz_recording.releases.select{|r2| r2.id == mbid}.first.media.first
      tracks_count_by_disc[medium.position] = medium.tracks.total_count
    end
    
    first_track_nr_of_disc = {}

    recordings.each do |musicbrainz_recording|
      medium = musicbrainz_recording.releases.select{|r2| r2.id == mbid}.first.media.first
      
      next if first_track_nr_of_disc.has_key? medium.position
      
      if medium.position.to_i == 1
        first_track_nr_of_disc[medium.position] = 1
        next
      end
      
      nr = 0
      
      tracks_count_by_disc.each do |disc_nr,tracks_count|
        break if disc_nr == medium.position
        
        nr += tracks_count
      end
      
      first_track_nr_of_disc[medium.position] = nr + 1
    end 
    
    first_track_nr_of_disc
  end 
   
  private
  
  def future_release_date_format
    return unless future_release_date.present?
    
    if future_release_date.match(/^XX\.[0-9]{2}\.[0-9]{4}$/)
      date = future_release_date.split('.')
      self.released_at = Date.civil(date[2].to_i, date[1].to_i, -1)
    elsif future_release_date.match(/^XX\.XX\.[0-9]{4}$/)
      date = future_release_date.split('.')
      self.released_at = Time.local(date[2], 12, 31)
    elsif future_release_date.match(/^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$/)
      date = future_release_date.split('.')
      self.released_at = Time.local(date[2], date[1], date[0])
    elsif future_release_date.match(/^(North|South) {1}(Spring|Summer|Autumn|Winter) {1}[0-9]{4}$/)
      date = future_release_date.split(' ')
      
      case "#{date[0]} #{date[1]}"
      when 'North Spring'
        self.released_at = Time.local(date[2], 6, 22)
      when 'North Summer'
        self.released_at = Time.local(date[2], 9, 23)
      when 'North Autumn'
        self.released_at = Time.local(date[2], 12, 22)
      when 'North Winter'
        self.released_at = Time.local(date[2], 3, 21)
      when 'South Spring'
        self.released_at = Time.local(date[2], 12, 22)
      when 'South Summer'
        self.released_at = Time.local(date[2], 3, 21)
      when 'South Autumn'
        self.released_at = Time.local(date[2], 6, 21)
      when 'South Winter'
        self.released_at = Time.local(date[2], 9, 23)
      end
    else
      errors[:future_release_date] << I18n.t('activerecord.errors.models.music_release.attributes.future_release_date.wrong_format')
    end
  end
  
  def set_artist_name
    return if artist_name.present?
    
    self.artist_name = artist.name
  end
  
  def sync_tracks
    track_attributes = {}
    
    track_attributes[:release_name] = name if name_changed?
    track_attributes[:released_at] = released_at if released_at_changed?
    
    return if track_attributes.empty?
    
    tracks.update_all track_attributes
  end
  
  def sync_year_in_review_music_releases
    year_in_review_music_releases_attributes = {}
    
    [:artist_name, :name, :released_at].each do |attribute|
      year_in_review_music_releases_attribute = attribute == :name ? :release_name : attribute
      year_in_review_music_releases_attributes[year_in_review_music_releases_attribute] = send(attribute) if send("#{attribute}_changed?")
    end
    
    return if year_in_review_music_releases_attributes.empty?
    
    YearInReviewMusicRelease.where(release_id: id).update_all year_in_review_music_releases_attributes
  end
end