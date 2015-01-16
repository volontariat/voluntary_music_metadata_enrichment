class MusicArtist < ActiveRecord::Base
  has_many :releases, class_name: 'MusicRelease', foreign_key: 'artist_id', dependent: :destroy
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'artist_id'
  
  validates :name, presence: true
  validates :mbid, presence: true, uniqueness: true
  
  after_save :synchronize_artist_name
  after_create :create_bonustracks_release
  
  attr_accessible :name, :mbid, :founded_at, :dissolved_at, :listeners, :plays
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |artist, transition|
      musicbrainz_artist = MusicBrainz::Artist.find(artist.mbid)
  
      artist.update_attributes(
        founded_at: artist.musicbrainz_date_to_iso_date(musicbrainz_artist.begin), 
        dissolved_at: artist.musicbrainz_date_to_iso_date(musicbrainz_artist.end)
      )
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_artist = lastfm.artist.get_info(mbid: artist.mbid)
      artist.update_attributes(listeners: lastfm_artist['stats']['listeners'], plays: lastfm_artist['stats']['playcount'])
  
      musicbrainz_artist.release_groups.select{|r| ['Album', 'EP'].include?(r.type) && !r.secondary_types.include?('Live') && r.artists.length == 1}.each do |musicbrainz_release_group|
        releases = musicbrainz_release_group.releases
        
        next if releases.select{|r| r.status == 'Official' && !r.media.map(&:format).include?('DVD-Video') && !r.media.map(&:format).include?('DVD')}.none?
        
        release = MusicRelease.create(artist_id: artist.id, artist_name: artist.name, name: musicbrainz_release_group.title)
        release.releases = releases
        release.import_metadata!
      end
    end
  end
  
  def bonus_tracks_release
    releases.where(name: '[Bonus tracks]').first
  end
  
  def musicbrainz_date_to_iso_date(date)
    return date if date.blank?
    
    splitted_date = date.split('-')
    
    if splitted_date.length == 1
      "#{splitted_date.first}-01-01"
    elsif splitted_date.length == 2
      "#{splitted_date.first}-#{splitted_date.last}-01"
    else
      date
    end
  end
  
  private
  
  def create_bonustracks_release
    release = releases.create(name: '[Bonus tracks]')
    release.update_attribute(:state, 'active')
  end
  
  def synchronize_artist_name
    return unless name_changed?
    
    [MusicRelease, MusicTrack, MusicVideo].each do |klass|
      klass.where('artist_id = ?', id).update_all ['artist_name = ?', name]
    end
  end
end