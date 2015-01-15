class MusicTrack < ActiveRecord::Base
  belongs_to :master_track, class_name: 'MusicTrack'
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :release, class_name: 'MusicRelease', counter_cache: true, counter_cache: 'tracks_count'
  
  has_many :videos, foreign_key: 'track_id', class_name: 'MusicVideo'
  
  validates :name, presence: true, uniqueness: { scope: :release_id }
  
  attr_accessible :mbid, :artist_id, :artist_name, :release_id, :release_name, :master_track_id, :nr, :name, :duration, :listeners, :plays
  
  before_create :set_master_track_id_if_available
  after_save :synchronize_track_name
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |track, transition|
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_track = lastfm.track.get_info(artist: track.artist_name, track: track.name) rescue nil
      track.update_attributes(listeners: lastfm_track['listeners'], plays: lastfm_track['playcount']) if lastfm_track.present?
    end
  end
  
  private
  
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