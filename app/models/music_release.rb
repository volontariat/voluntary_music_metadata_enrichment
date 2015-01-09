class MusicRelease < ActiveRecord::Base
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :user
  
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'release_id', dependent: :destroy
  
  validates :artist_id, presence: true
  validates :name, presence: true, uniqueness: { scope: :artist_id }
  validates :mbid, uniqueness: true
  
  after_save :synchronize_release_name
  
  attr_accessible :mbid, :artist_id, :artist_name, :name, :future_release_date, :released_at, :listeners, :plays
  
  attr_accessor :releases
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |release, transition|
      musicbrainz_release = nil
      highest_tracks_count = 0
      earliest_release_date = Time.now
      
      release.releases.each do |working_musicbrainz_release|
        next unless working_musicbrainz_release.status == 'Official'
        
        working_tracks_count = working_musicbrainz_release.media.map{|m| m.tracks.total_count }.inject{|sum,x| sum + x }
        
        if working_tracks_count > highest_tracks_count
          highest_tracks_count = working_tracks_count
          musicbrainz_release = working_musicbrainz_release
        end
        
        if musicbrainz_release.date != nil && musicbrainz_release.date < earliest_release_date
          earliest_release_date = musicbrainz_release.date
        end
      end
      
      release.update_attributes(mbid: musicbrainz_release.id, released_at: earliest_release_date)
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_album = lastfm.album.get_info(artist: release.artist_name, album: release.name)
      release.update_attributes(listeners: lastfm_album['listeners'], plays: lastfm_album['playcount'])
      
      #musicbrainz_release = MusicBrainz::Release.find(mbid, [:recordings])
      nr = 1
      
      MusicBrainz::Recording.by_release_id(musicbrainz_release.id).each do |musicbrainz_recording|
        track = MusicTrack.create(
          mbid: musicbrainz_recording.id, artist_id: release.artist_id, artist_name: release.artist_name, 
          release_id: release.id, release_name: release.name, nr: nr, name: musicbrainz_recording.title, 
          duration: musicbrainz_recording.length
        )
        track.import_metadata!
        
        nr += 1
      end
    end
  end
  
  private
  
  def synchronize_release_name
    return unless name_changed?
    
    [MusicTrack].each do |klass|
      klass.where(['release_id = ?', id]).update_all ['release_name = ?', name]
    end
  end
end