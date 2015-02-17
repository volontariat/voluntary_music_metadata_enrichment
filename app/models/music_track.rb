# -*- encoding : utf-8 -*-
class MusicTrack < ActiveRecord::Base
  include LastfmRequest
  
  belongs_to :master_track, class_name: 'MusicTrack'
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :release, class_name: 'MusicRelease', counter_cache: true, counter_cache: 'tracks_count'
  
  has_many :videos, foreign_key: 'track_id', class_name: 'MusicVideo', dependent: :destroy
  has_many :group_year_in_review_tops, foreign_key: 'track_id', class_name: 'MusicMetadataEnrichment::GroupYearInReviewTrack', dependent: :destroy
  has_many :year_in_review_flops, foreign_key: 'track_id', class_name: 'YearInReviewMusicTrackFlop', dependent: :destroy
  has_many :year_in_review_tops, foreign_key: 'track_id', class_name: 'YearInReviewMusicTrack', dependent: :destroy
  
  scope :without_slaves, -> { where('music_tracks.master_track_id IS NULL') }
  
  scope :released_in_year, ->(year) do
    where("music_tracks.released_at >= :from AND music_tracks.released_at <= :to", from: Time.local(year,1,1,0,0,0), to: Time.local(year,12,31,23,59,59))
  end
  
  scope :for_year_in_review, ->(year_in_review) do
    track_ids = year_in_review.tracks.map(&:track_id)
    tracks = released_in_year(year_in_review.year)
    tracks = tracks.where('music_tracks.id NOT IN(?)', track_ids) if track_ids.any?
    tracks = tracks.without_flops(year_in_review.id)
    tracks
  end
  
  scope :without_flops, ->(year_in_review_id) do
    joins("LEFT JOIN year_in_review_music_track_flops ON year_in_review_music_track_flops.year_in_review_music_id = #{year_in_review_id} AND year_in_review_music_track_flops.track_id = music_tracks.id").
    where('year_in_review_music_track_flops.id IS NULL')
  end
  
  def self.by_artist_and_name(artist_name, name)
    without_slaves.where(
      "LOWER(artist_name) = :artist_name AND LOWER(name) = :name", 
      artist_name: artist_name.downcase.strip, name: name.downcase.strip
    )
  end
  
  scope :artist_and_name_like, ->(artist_name, name) do
    table = MusicTrack.arel_table
    where(table[:artist_name].matches("%#{artist_name}%").and(table[:name].matches("%#{name}%")))
  end
  
  validates :name, length: { maximum: 255 }, uniqueness: { scope: :release_id, case_sensitive: false }
  validates :mbid, allow_blank: true, uniqueness: true, length: { is: 36 }
  validates :spotify_track_id, length: { is: 22 }, allow_blank: true
  validate :name_not_included_in_blacklist
  
  attr_accessible :mbid, :artist, :artist_id, :artist_name, :release_id, :release_name, :master_track_id, :nr, :name, :duration, :listeners, :plays
  
  attr_accessor :artist_mbid, :release_is_lp, :do_not_sync
  
  before_validation :gsub_name
  before_create :set_artist_name
  before_create :set_release_name
  before_create :set_released_at
  before_create :set_master_track_id_if_available
  after_update :sync_video_track_name
  after_update :sync_year_in_review_music_tracks
  after_destroy :destroy_slaves
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |track, transition|
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_track = track.lastfm_request(lastfm, :track, :get_info, /Artist not found|Track not found/, artist: track.artist_name, track: track.name)

      unless lastfm_track.nil?
        attributes = { listeners: lastfm_track['listeners'], plays: lastfm_track['playcount'] }
        attributes[:duration] = lastfm_track['duration'] if track.duration.blank?
        track.update_attributes(attributes)
      end
      
      track.set_spotify_track_id
    end
  end
  
  def self.search_on_musicbrainz(artist_mbid, name)
    results = []
    tracks = MusicBrainz::Recording.search(artist_mbid, name)

    tracks.each do |track|
      results << track if results.select{|t| t[:title].downcase == name.downcase.strip }.none?
    end
    
    results
  end
  
  def self.format_name(value)
    return value if value.nil?
    
    value.gsub(/’|´/, "'").gsub(/\(Album version\)|\(Single version\)|\(Remastered\)|\(clean\)/i, '').strip
  end
  
  def self.name_included_in_blacklist?(name)
    if name =~ /\[credits|data track|encore break|untitled|photo gallery|interview\]/i
      true
    else
      false
    end
  end
  
  def self.name_included_in_bonustrack_blacklist?(name)
    if name_included_in_blacklist?(name)
      true
    elsif name =~ /^intro|introduction|outro|credits|interview$/i
      true
    elsif name =~ /\[intro|outro|introduction\]/i 
      true
    elsif name =~ /medley|megamix|mega mix|mastermix|master mix|acoustic/i
      true
    elsif name =~ /\(/
      true
    else
      false
    end
  end
  
  def set_spotify_track_id
    return if spotify_track_id.present?

    response = nil
    
    begin
      response = JSON.parse(
        HTTParty.get("https://api.spotify.com/v1/search?q=track%3A%22#{URI.encode(name, /\W/)}%22+artist%3A%22#{URI.encode(artist_name, /\W/)}%22&type=track").body
      )
    rescue JSON::ParserError
    end
    
    return if response.nil?
    
    response['tracks']['items'].each do |item|
      next unless item['name'].downcase == name.downcase
      
      artist_found = false
      
      item['artists'].each do |working_artist|
        if working_artist['name'].downcase == artist_name.downcase
          artist_found = true
          
          break
        end
      end
      
      next unless artist_found
      
      self.spotify_track_id = item['id']

      break if item['artists'].length == 1
    end
    
    save if spotify_track_id.present?
  end
  
  def is_bonus_track?
    return false if ::MusicTrack.name_included_in_bonustrack_blacklist?(name)
    
    tracks = MusicBrainz::Recording.search(artist_mbid ? artist_mbid : artist.mbid, name, limit: 100).select{|t| MusicTrack.format_name(t[:title]).downcase == name.downcase.strip }
    
    tracks.map do |t| 
      (t[:releases] || []).select do |r| 
        r[:status] == 'Official' && !(r[:artists] || []).map{|a| a[:name]}.include?('Various Artists') &&
        (r[:release_group][:secondary_types] || []).select{|st| MusicRelease::SECONDARY_TYPES_BLACKLIST.include?(st)}.none?
      end.map{|r| (r[:release_group] || {})[:id] }
    end.flatten.uniq.each do |release_group_mbid|
      next if release_group_mbid.nil?
      
      release_group = nil
      
      3.times do
        release_group = MusicBrainz::ReleaseGroup.find(release_group_mbid)
        
        break unless release_group.nil?
        
        sleep 30
      end
          
      next if release_group.releases.select{|r| r.status != 'Official' || (r.media.map(&:format).any? && r.media.map(&:format).select{|m| ['DVD-Video', 'DVD'].select{|m2| m == m2 }.none?}.none?) }
      next unless ['Album', 'EP'].include?(release_group.primary_type)
    
      self.release_name = release_group.title
      self.release_is_lp = release_group.type == 'Album'
      
      break
    end
    
    if self.release_name.blank?
      self.released_at = tracks.map{|t| (t[:releases] || []).select{|r| !r[:date].nil?}.map{|r| r[:date]}}.flatten.uniq.sort.first
      
      true
    else
      false
    end
  end
  
  def create_bonus_track(working_mbid)
    self.name = MusicTrack.format_name(name)
    self.mbid = working_mbid
    self.release_id = artist.bonus_tracks_release.id
    self.save
    self.import_metadata!
  end
  
  def create_draft_track(name)
    self.release_id = artist.bonus_tracks_release.id
    self.name = MusicTrack.format_name(name)
    self.save
  end
  
  def formatted_duration
    Time.at(duration / 1000).strftime('%M:%S') if duration.present?
  end
  
  private
  
  def name_not_included_in_blacklist
    if ::MusicTrack.name_included_in_blacklist?(name) 
      errors[:name] << I18n.t('activerecord.errors.models.music_metadata_enrichment_group.attributes.name.included_in_blacklist')
    end
  end
  
  def gsub_name
    self.name = MusicTrack.format_name(name)
  end
  
  def set_artist_name
    return if artist_name.present?
    
    self.artist_name = artist.name
  end

  def set_release_name
    return if release_name.present?
    
    self.release_name = release.name
  end
  
  def set_released_at
    return if released_at.present?
      
    self.released_at = release.released_at
  end
  
  def set_master_track_id_if_available
    if track = MusicTrack.where(
      'artist_id = :artist_id AND release_id <> :bonus_release_id AND master_track_id IS NULL AND LOWER(name) = :name', 
      artist_id: artist_id, bonus_release_id: release.artist.bonus_tracks_release.id, name: name.downcase
    ).first
      self.master_track_id = track.id
    end  
  end
  
  def sync_video_track_name
    return unless name_changed?
    
    MusicVideo.where(['track_id = ?', id]).update_all ['track_name = ?', name]
  end
  
  def sync_year_in_review_music_tracks
    return if do_not_sync
    
    year_in_review_music_tracks_attributes = {}
    
    [:artist_name, :release_name, :id, :spotify_track_id, :name, :released_at].each do |attribute|
      year_in_review_music_tracks_attribute = case attribute
      when :id then :track_id
      when :name then :track_name
      else attribute
      end
      
      year_in_review_music_tracks_attributes[year_in_review_music_tracks_attribute] = send(attribute) if send("#{attribute}_changed?")
    end
    
    return if year_in_review_music_tracks_attributes.empty?
    
    YearInReviewMusicTrack.where(track_id: id).update_all year_in_review_music_tracks_attributes
    YearInReviewMusicTrackFlop.where(track_id: id).update_all year_in_review_music_tracks_attributes
    MusicMetadataEnrichment::GroupYearInReviewTrack.where(track_id: id).update_all year_in_review_music_tracks_attributes
  end
  
  def destroy_slaves
    MusicTrack.where(master_track_id: id).destroy_all if master_track_id.blank?
  end
end