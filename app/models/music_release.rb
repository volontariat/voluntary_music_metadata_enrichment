# -*- encoding : utf-8 -*-
class MusicRelease < ActiveRecord::Base
  include LastfmRequest
  
  SECONDARY_TYPES_BLACKLIST = ['Audiobook', 'Compilation', 'DJ-mix', 'Interview', 'Live', 'Remix', 'Spokenword', 'Mixtape/Street']
  
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :user
  
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'release_id', dependent: :destroy
  has_many :group_year_in_review_tops, foreign_key: 'release_id', class_name: 'MusicMetadataEnrichment::GroupYearInReviewRelease', dependent: :destroy
  has_many :year_in_review_flops, foreign_key: 'release_id', class_name: 'YearInReviewMusicReleaseFlop', dependent: :destroy
  has_many :year_in_review_tops, foreign_key: 'release_id', class_name: 'YearInReviewMusicRelease', dependent: :destroy
  
  def self.by_artist_and_name(releases)
    # TODO: monitor if there are artists with multiple releases with the same name
    criteria, values = [], []
    
    releases.each do |release|
      criteria << '(LOWER(artist_name) = ? AND LOWER(name) = ?)'
      values += [release.first.downcase.strip, release.last.downcase.strip]
    end
    
    where(criteria.join(' OR '), *values)
  end
  
  def self.enrich_metadata(releases_input)
    primitive_releases = []
    
    releases_input = if releases_input.is_a? Hash
      list = []
      releases_input.each {|index, release| list << release }
      list
    else
      releases_input
    end
    
    releases_input.each do |release|
      primitive_releases << [release['artist_name'].downcase.strip, release['name'].downcase.strip]
    end
    
    releases = MusicRelease.by_artist_and_name(primitive_releases).limit(500).offset(0)
    primitive_voluntary_releases = releases.map{|t| [t.artist_name.downcase.strip, t.name.downcase.strip]}
    
    unique_primitive_voluntary_releases = primitive_voluntary_releases.select{|t1| primitive_voluntary_releases.select{|t2| t2 == t1 }.length == 1 }
    ambiguous_primitive_voluntary_releases = primitive_voluntary_releases.select{|t1| primitive_voluntary_releases.select{|t2| t2 == t1 }.length > 1 }
    
    new_releases, already_existing_releases = [], []
    
    # make releases uniq this way because releases.uniq removes not persisted releases
    releases.each do |release|
      primitive_release = [release.artist_name.downcase, release.name.downcase]
      
      next if already_existing_releases.include?(primitive_release)
      
      already_existing_releases << primitive_release
    end
    
    primitive_releases.select{|t| !unique_primitive_voluntary_releases.include?(t) }.each do |release|
      release_input = releases_input.select{|t| t['artist_name'].downcase.strip == release.first && t['name'].downcase.strip == release.last}.first
      release = MusicRelease.new(artist_name: release_input['artist_name'], name: release_input['name'])
      release.set_spotify_album_id
      sleep 1
      releases << release
    end
    
    releases.map do |release| 
      hash = { 
        artist_name: release.artist_name, name: release.name
      }
      
      if release.persisted?
        hash[:ambiguous] = ambiguous_primitive_voluntary_releases.include?([release.artist_name.strip.downcase, release.name.strip.downcase])
      else
        hash[:ambiguous] = nil
      end
      
      if hash[:ambiguous]
        hash.merge({
          id: nil, artist_id: nil, mbid: nil, spotify_id: nil, listeners: nil, plays: nil, released_at: nil,
          future_release_date: nil, is_lp: nil
        })
      else
        hash.merge({
          id: release.id, artist_id: release.artist_id, mbid: release.mbid, spotify_id: release.spotify_album_id,
          listeners: release.listeners, plays: release.plays, released_at: release.released_at,
          future_release_date: release.future_release_date, is_lp: release.persisted? ? release.is_lp : nil
        })
      end
    end
  end
  
  scope :artist_and_name_like, ->(artist_name, name) do
    table = MusicRelease.arel_table
    where(table[:artist_name].matches("%#{artist_name}%").and(table[:name].matches("%#{name}%")))
  end
  
  scope :released_in_year, ->(year) do
    where("music_releases.released_at >= :from AND music_releases.released_at <= :to", from: Time.local(year,1,1,0,0,0), to: Time.local(year,12,31,23,59,59))
  end
  
  scope :for_year_in_review, ->(year_in_review) do
    release_ids = year_in_review.releases.map(&:release_id)
    releases = released_in_year(year_in_review.year)
    releases = releases.where('music_releases.id NOT IN(?)', release_ids) if release_ids.any?
    releases = releases.without_flops(year_in_review.id)
    releases
  end
  
  scope :without_flops, ->(year_in_review_id) do
    joins("LEFT JOIN year_in_review_music_release_flops ON year_in_review_music_release_flops.year_in_review_music_id = #{year_in_review_id} AND year_in_review_music_release_flops.release_id = music_releases.id").
    where('year_in_review_music_release_flops.id IS NULL')
  end
  
  validates :artist_id, presence: true
  validates :name, presence: true, uniqueness: { scope: [:artist_id, :is_lp] }
  validates :mbid, uniqueness: true, allow_blank: true, length: { is: 36 }
  validate :future_release_date_format
  validates :spotify_album_id, length: { is: 22 }, allow_blank: true
  
  before_save :set_artist_name
  after_update :sync_tracks
  after_update :sync_year_in_review_music_releases
  
  attr_accessible :mbid, :artist_id, :artist_name, :is_lp, :name, :future_release_date, :released_at, :listeners, :plays
  
  attr_accessor :releases
  
  after_initialize :set_initial_state
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |release, transition|
      releases = if release.releases.nil?
        release.find_releases
      else
        release.releases
      end
      
      releases = release.prefered_releases(releases)
      release_date = release.get_earliest_release_date(releases)
      
      if releases.select{|r| r.media.map(&:format).include?('CD') }.any?
        releases = releases.select{|r| r.media.map(&:format).include?('CD') }
      end
      
      musicbrainz_release, dvd_recording_mbids = release.release_with_highest_tracks_count(releases)
      release.update_attributes(mbid: musicbrainz_release.id, released_at: release_date)
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_album = release.lastfm_request(lastfm, :album, :get_info, /Artist not found|Album not found/, artist: release.artist_name, album: release.name)
      release.update_attributes(listeners: lastfm_album['listeners'], plays: lastfm_album['playcount']) unless lastfm_album.nil?
      
      release.set_spotify_album_id
      
      musicbrainz_release = MusicBrainz::Release.find(release.mbid, [:recordings])
      first_track_nr_of_disc = release.get_first_track_nr_of_disc(musicbrainz_release)
      bonus_tracks_release_id = release.artist.bonus_tracks_release.id
      
      musicbrainz_release.media.each do |medium|
        medium.tracks.each do |track|
          musicbrainz_recording = track.recording
          
          next if dvd_recording_mbids.include? musicbrainz_recording.id
          
          track_name = MusicTrack.format_name(musicbrainz_recording.title)
          
          if musicbrainz_recording.disambiguation.present? && !track_name.match('\(') && !musicbrainz_recording.disambiguation.match(/Album version|Single version/i)
            # example: http://musicbrainz.org/release/e3f92095-5466-3a96-8dc3-f5c86c35a954
            track_name = "#{track_name} (#{musicbrainz_recording.disambiguation})"
          end
          
          nr = first_track_nr_of_disc[medium.position] + track.number.to_i - 1
          
          track = nil
          
          begin
            track = MusicTrack.create(
              mbid: musicbrainz_recording.id, artist_id: release.artist_id, artist_name: release.artist_name, 
              release_id: release.id, release_name: release.name, nr: nr, name: track_name, 
              duration: musicbrainz_recording.length
            )
            
            if track.persisted?
              draft_track = MusicTrack.where(
                'release_id = :release_id AND master_track_id IS NULL AND LOWER(name) = :name', 
                release_id: bonus_tracks_release_id, name: track_name.downcase
              ).first  
              
              if draft_track.present?
                puts "track ##{track.id}: draft track ##{draft_track.try(:id).inspect} present" if track.name.downcase.match('summer')
                
                [
                  MusicMetadataEnrichment::GroupYearInReviewTrack, MusicVideo, YearInReviewMusicTrackFlop, YearInReviewMusicTrack
                ].each do |klass|
                  klass.where(track_id: draft_track.id).each do |record|
                    record.update_attribute(:track_id, track.id)
                    if record.valid?
                      puts "track ##{track.id}: #{record.class.name} ##{record.id} is valid." if track.name.downcase.match('summer')
                    else
                      puts "track ##{track.id}: #{record.class.name} ##{record.id} is invalid: #{track.errors.full_messages.join('.')}" if track.name.downcase.match('summer')
                    end
                  end
                end
                
                draft_track.destroy
                puts "track ##{track.id} tried to destroy draft track: #{draft_track.persisted?.inspect}" if track.name.downcase.match('summer')
              end
            end
          rescue ActiveRecord::RecordNotUnique
          end
          
          # no bang because of releases like the following which includes the same track multiple times: http://musicbrainz.org/release/2b18f9eb-b171-4fd6-ab1f-9801c4adc992
          if track.try(:id)
            track.do_not_sync = true
            track.import_metadata
          end
        end
      end
    end
  end
  
  def find_releases
    musicbrainz_release_group, musicbrainz_releases = nil, nil
    
    if mbid.present?
      musicbrainz_release = MusicBrainz::Release.find(mbid)
      
      unless musicbrainz_release.nil?
        musicbrainz_release_group = musicbrainz_release.release_group
        musicbrainz_release_group.releases = nil
        musicbrainz_releases = musicbrainz_release_group.releases
        musicbrainz_release_group = musicbrainz_release_group.to_primitive
      end
    end
    
    if musicbrainz_release_group.nil?
      list = groups(false, true).select{|a| ((is_lp && a.first[:type] == 'Album') || (!is_lp && a.first[:type] != 'Album')) && a.first[:title].downcase == name.downcase }.first
      
      return [] if list.nil?
      
      musicbrainz_release_group, musicbrainz_releases = list
    end
    
    update_attribute(:is_lp, musicbrainz_release_group[:type] == 'Album' ? true : false)
    
    musicbrainz_releases
  end
  
  def self.format_lastfm_name(name)
    return name if name.nil?
    
    name.gsub(/\(Deluxe Edition\)|\(Deluxe\)|\(Deluxe Version\)|\(Deluxe Package\)|\(Bonus Version\)|\(Legacy Edition\)|\(Standard Version\)|\(Remastered Version\)|\(Remastered\)/i, '').strip
  end
  
  def set_spotify_album_id
    return if spotify_album_id.present?

    response = nil
    
    begin
      response = JSON.parse(
        HTTParty.get("https://api.spotify.com/v1/search?q=album%3A%22#{URI.encode(name, /\W/)}%22+artist%3A%22#{URI.encode(artist_name, /\W/)}%22&type=album").body
      )
    rescue JSON::ParserError
    end
    
    return if response.nil?
    
    response['albums'] ||= { 'items' => [] }
    
    response['albums']['items'].each do |item|
      next unless item['name'].downcase == name.downcase
      
      self.spotify_album_id = item['id']

      break
    end
    
    save if persisted? && spotify_album_id.present?
  end
  
  def groups(without_limitation, with_releases = false)
    musicbrainz_release_groups = MusicBrainz::ReleaseGroup.search(artist.mbid, name) #extra_query: 'AND (type:album OR type:ep OR type:soundtrack)')
    
    if musicbrainz_release_groups.none?
      count, musicbrainz_release_groups = artist.release_groups(nil, [], 0, without_limitation)
      musicbrainz_release_groups = musicbrainz_release_groups.map(&:to_primitive) 
    end
    
    musicbrainz_release_groups = musicbrainz_release_groups.select do |rg| 
      ['Album', 'Soundtrack', 'EP'].include?(rg[:type]) &&
      !rg[:releases].nil? && rg[:releases].select{|r| r[:status] == 'Official'}.any? && 
      (rg[:secondary_types].nil? || rg[:secondary_types].select{|st| SECONDARY_TYPES_BLACKLIST.include?(st)}.none?) && 
      rg[:artists].length == 1
    end
    
    unless without_limitation
      working_groups = []
      
      musicbrainz_release_groups.each do |hash|
        musicbrainz_release_group = MusicBrainz::ReleaseGroup.find(hash[:id])
        musicbrainz_release_group.releases = nil
        musicbrainz_releases = musicbrainz_release_group.releases
          
        next if musicbrainz_releases.select{|r| r.status == 'Official' && (r.media.map(&:format).none? || r.media.map(&:format).select{|f| !['DVD-Video', 'DVD'].include?(f) }.any?) }.none?
      
        working_groups << (with_releases ? [hash, musicbrainz_releases] : hash)
      end
      
      musicbrainz_release_groups = working_groups
    end
    
    musicbrainz_release_groups
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
      
      next if working_musicbrainz_release.media.map(&:format).any? && working_musicbrainz_release.media.map(&:format).select{|f| !['DVD-Video', 'DVD'].include?(f) }.none?
      
      list << working_musicbrainz_release
    end    
    
    list
  end
  
  def get_earliest_release_date(working_releases)
    earliest_release_date = nil
    
    working_releases.each do |working_musicbrainz_release|
      if working_musicbrainz_release.date != nil && (earliest_release_date == nil || working_musicbrainz_release.date < earliest_release_date)
        earliest_release_date = working_musicbrainz_release.date
      end
    end
    
    earliest_release_date
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
   
  def get_first_track_nr_of_disc(musicbrainz_release)
    tracks_count_by_disc = {}
     
    musicbrainz_release.media.each do |medium|
      tracks_count_by_disc[medium.position] = medium.tracks.total_count
    end
    
    first_track_nr_of_disc = {}

    musicbrainz_release.media.each do |medium|
      if medium.position.to_i == 1
        first_track_nr_of_disc[medium.position] = 1
        
        next
      end
      
      nr = 0
      
      tracks_count_by_disc.keys.sort.each do |disc_nr|
        tracks_count = tracks_count_by_disc[disc_nr]
        
        break if disc_nr == medium.position
        
        nr += tracks_count
      end
      
      first_track_nr_of_disc[medium.position] = nr + 1
    end
    
    first_track_nr_of_disc
  end 
   
  def to_json
    {
      id: id, mbid: mbid, spotify_id: spotify_album_id, is_lp: is_lp, 
      artist_id: artist_id, artist_name: artist_name, name: name,
      future_release_date: future_release_date, 
      released_at: released_at.try(:iso8601), listeners: listeners, 
      plays: plays, state: state
    }
  end  
   
  private
  
  def set_initial_state
    self.state ||= :without_metadata
  end
  
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
    
    [:artist_name, :name, :released_at, :spotify_album_id].each do |attribute|
      year_in_review_music_releases_attribute = attribute == :name ? :release_name : attribute
      year_in_review_music_releases_attributes[year_in_review_music_releases_attribute] = send(attribute) if send("#{attribute}_changed?")
    end
    
    return if year_in_review_music_releases_attributes.empty?
    
    YearInReviewMusicRelease.where(release_id: id).update_all year_in_review_music_releases_attributes
    YearInReviewMusicReleaseFlop.where(release_id: id).update_all year_in_review_music_releases_attributes
    MusicMetadataEnrichment::GroupYearInReviewRelease.where(release_id: id).update_all year_in_review_music_releases_attributes
  end
end