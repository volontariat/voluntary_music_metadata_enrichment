# -*- encoding : utf-8 -*-
class MusicRelease < ActiveRecord::Base
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :user
  
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'release_id', dependent: :destroy
  
  validates :artist_id, presence: true
  validates :name, presence: true
  validates :mbid, uniqueness: true, allow_blank: true
  validate :future_release_date_format
  
  before_save :set_artist_name
  after_save :synchronize_release_name
  
  attr_accessible :mbid, :artist_id, :artist_name, :name, :future_release_date, :released_at, :listeners, :plays
  
  attr_accessor :releases
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |release, transition|
      musicbrainz_release = nil
      highest_tracks_count = 0
      earliest_release_date = Time.now
      
      releases = if release.releases.nil?
        MusicBrainz::ReleaseGroup.find(release.groups.select{|r| r[:title] == release.name }.first[:id]).releases
      else
        release.releases
      end
      
      releases.each do |working_musicbrainz_release|
        next unless working_musicbrainz_release.status == 'Official'
        
        # TODO: handle case where count of tracks which are not on a dvd is still the highest and only import tracks which are not a DVD
        next if working_musicbrainz_release.media.map(&:format).include?('DVD-Video')

        working_tracks_count = working_musicbrainz_release.media.map{|m| m.tracks.total_count }.inject{|sum,x| sum + x }
        
        if working_tracks_count > highest_tracks_count
          highest_tracks_count = working_tracks_count
          musicbrainz_release = working_musicbrainz_release
        end
        
        if working_musicbrainz_release.date != nil && working_musicbrainz_release.date < earliest_release_date
          earliest_release_date = working_musicbrainz_release.date
        end
      end

      release.update_attributes(mbid: musicbrainz_release.id, released_at: earliest_release_date)
      
      begin
        lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
        lastfm_album = lastfm.album.get_info(artist: release.artist_name, album: release.name)
        release.update_attributes(listeners: lastfm_album['listeners'], plays: lastfm_album['playcount'])
      rescue Lastfm::ApiError
        # rescue from album not found
      end
      
      #musicbrainz_release = MusicBrainz::Release.find(mbid, [:recordings])
      nr, recordings = 1, nil
      
      3.times do
        recordings = MusicBrainz::Recording.by_release_id(musicbrainz_release.id)
        
        break if recordings.respond_to? :each
        
        sleep 60
      end
      
      recordings.each do |musicbrainz_recording|
        track_name = MusicTrack.format_name(musicbrainz_recording.title)
        
        if musicbrainz_recording.disambiguation.present? && !track_name.match('\(') && !musicbrainz_recording.disambiguation.match(/Album version|Single version/i)
          # example: http://musicbrainz.org/release/e3f92095-5466-3a96-8dc3-f5c86c35a954
          track_name = "#{track_name} (#{musicbrainz_recording.disambiguation})"
        end
        
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
        track.import_metadata if track
        
        nr += 1
      end
    end
  end
  
  def groups
    musicbrainz_release_groups = MusicBrainz::ReleaseGroup.search(artist.mbid, name, extra_query: 'AND (type:album OR type:ep)')
    musicbrainz_release_groups.select{|rg| rg[:releases].select{|r| r[:status] == 'Official'}.any? && (rg[:secondary_types].nil? || rg[:secondary_types].select{|st| ['Compilation', 'Live', 'Remix'].include?(st)}.none?) && rg[:artists].length == 1 }
  end
 
  def groups_without_limitation
    MusicBrainz::ReleaseGroup.search_by_artist_mbid(artist.mbid, name)
  end
   
  def formatted_released_at_or_future_release_date 
    if future_release_date.present? then future_release_date
    elsif released_at.present? then released_at.strftime('%d.%m.%Y')
    else nil
    end
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
  
  def synchronize_release_name
    return unless name_changed?
    
    tracks.update_all(release_name: name)
  end
end