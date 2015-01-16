class MusicTrack < ActiveRecord::Base
  belongs_to :master_track, class_name: 'MusicTrack'
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :release, class_name: 'MusicRelease', counter_cache: true, counter_cache: 'tracks_count'
  
  has_many :videos, foreign_key: 'track_id', class_name: 'MusicVideo'
  
  validates :name, presence: true, uniqueness: { scope: :release_id }
  
  attr_accessible :mbid, :artist_id, :artist_name, :release_id, :release_name, :master_track_id, :nr, :name, :duration, :listeners, :plays
  
  before_save :set_artist_name
  before_save :set_release_name
  before_create :set_released_at
  before_create :set_master_track_id_if_available
  after_save :synchronize_track_name
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |track, transition|
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_track = lastfm.track.get_info(artist: track.artist_name, track: track.name) rescue nil
      attributes = { listeners: lastfm_track['listeners'], plays: lastfm_track['playcount'] }
      attributes[:duration] = lastfm_track['duration'] if track.duration.blank?
      track.update_attributes(attributes) if lastfm_track.present?
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
  
  def is_bonus_track?
    musicbrainz_artist = MusicBrainz::Artist.find(artist.mbid)
    tracks = MusicBrainz::Recording.search(artist.mbid, name, limit: 100).select{|t| t[:title].downcase == name.downcase.strip }
    
    tracks.map do |t| 
      (t[:releases] || []).select do |r| 
        r[:status] == 'Official' && !(r[:artists] || []).map{|a| a[:name]}.include?('Various Artists') && 
        ['Album', 'EP'].include?((r[:release_group] || {})[:primary_type]) &&
        (r[:release_group][:secondary_types] || []).select{|st| ['Compilation', 'Live', 'Remix'].include?(st)}.none?
      end.map{|r| r[:title]}
    end.flatten.uniq.each do |working_release_name|
      release_group = musicbrainz_artist.release_groups.select{|rg| rg.title.downcase == working_release_name.downcase}.first
  
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
  
  private
  
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
  
  def synchronize_track_name
    return unless name_changed?
    
    MusicVideo.where(['track_id = ?', id]).update_all ['track_name = ?', name]
  end
end