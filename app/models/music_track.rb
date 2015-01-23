# -*- encoding : utf-8 -*-
class MusicTrack < ActiveRecord::Base
  belongs_to :master_track, class_name: 'MusicTrack'
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :release, class_name: 'MusicRelease', counter_cache: true, counter_cache: 'tracks_count'
  
  has_many :videos, foreign_key: 'track_id', class_name: 'MusicVideo'
  
  scope :without_slaves, -> { where('music_tracks.master_track_id IS NULL') }
  
  scope :released_in_year, ->(year) do
    where("released_at >= :from AND released_at <= :to", from: Time.local(year,1,1,0,0,0), to: Time.local(year,12,31,23,59,59))
  end
  
  def self.find_by_artist_and_name(artist_name, name)
    without_slaves.where(
      "LOWER(artist_name) = :artist_name AND LOWER(name) = :name", 
      artist_name: artist_name.downcase.strip, name: name.downcase.strip
    ).first
  end
  
  scope :artist_and_name_like, ->(artist_name, name) do
    table = MusicTrack.arel_table
    where(table[:artist_name].matches("%#{artist_name}%").and(table[:name].matches("%#{name}%")))
  end
  
  validates :name, presence: true, uniqueness: { scope: :release_id, case_sensitive: false }
  validates :mbid, presence: true, uniqueness: true, length: { is: 36 }
  validates :spotify_track_id, length: { is: 22 }, allow_blank: true
  
  attr_accessible :mbid, :artist_id, :artist_name, :release_id, :release_name, :master_track_id, :nr, :name, :duration, :listeners, :plays
  
  attr_accessor :artist_mbid
  
  before_validation :gsub_name
  before_create :set_artist_name
  before_create :set_release_name
  before_create :set_released_at
  before_create :set_master_track_id_if_available
  after_update :sync_video_track_name
  after_update :sync_year_in_review_music_tracks
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |track, transition|
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_track = lastfm.track.get_info(artist: track.artist_name, track: track.name) rescue nil
      
      if lastfm_track.present?
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
      artist_found = false
      
      item['artists'].each do |working_artist|
        if working_artist['name'].downcase == artist_name.downcase
          artist_found = true
          
          break
        end
      end
      
      next unless artist_found
      
      next unless item['name'].downcase == name.downcase
      
      update_attribute(:spotify_track_id, item['id'])
      
      break
    end
  end
  
  def is_bonus_track?
    tracks = MusicBrainz::Recording.search(artist_mbid ? artist_mbid : artist.mbid, name, limit: 100).select{|t| MusicTrack.format_name(t[:title]).downcase == name.downcase.strip }
    
    tracks.map do |t| 
      (t[:releases] || []).select do |r| 
        r[:status] == 'Official' && !(r[:artists] || []).map{|a| a[:name]}.include?('Various Artists') && 
        ['Album', 'EP'].include?((r[:release_group] || {})[:primary_type]) &&
        (r[:release_group][:secondary_types] || []).select{|st| ['Audiobook', 'Compilation', 'Live', 'Remix'].include?(st)}.none?
      end.map{|r| (r[:release_group] || {})[:id] }
    end.flatten.uniq.each do |release_group_mbid|
      next if release_group_mbid.nil?
      
      release_group = nil
      
      3.times do
        release_group = MusicBrainz::ReleaseGroup.find(release_group_mbid)
        
        break unless release_group.nil?
        
        sleep 30
      end
          
      next if release_group.releases.select{|r| r.status == 'Official' && r.media.map(&:format).select{|m| ['DVD-Video', 'DVD'].select{|m2| m == m2 }.any?}.none? }
    
      self.release_name = working_release_name
      
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
    self.mbid = working_mbid
    self.release_id = artist.bonus_tracks_release.id
    self.save
    self.import_metadata!
  end
  
  def formatted_duration
    Time.at(duration / 1000).strftime('%M:%S')
  end
  
  private
  
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
    if track = MusicTrack.where(artist_id: artist_id, name: name).first
      self.master_track_id = track.id
    end  
  end
  
  def sync_video_track_name
    return unless name_changed?
    
    MusicVideo.where(['track_id = ?', id]).update_all ['track_name = ?', name]
  end
  
  def sync_year_in_review_music_tracks
    year_in_review_music_tracks_attributes = {}
    
    [:artist_name, :release_name, :id, :spotify_track_id, :name].each do |attribute|
      year_in_review_music_tracks_attribute = case attribute
      when :id then :track_id
      when :name then :track_name
      else attribute
      end
      
      year_in_review_music_tracks_attributes[year_in_review_music_tracks_attribute] = send(attribute) if send("#{attribute}_changed?")
    end
    
    return if year_in_review_music_tracks_attributes.empty?
    
    YearInReviewMusicTrack.where(track_id: id).update_all year_in_review_music_tracks_attributes
  end
end