module MusicMetadataEnrichment
  class Group < ActiveRecord::Base
    self.table_name = 'music_metadata_enrichment_groups'
    
    has_many :artist_connections, class_name: 'MusicMetadataEnrichment::GroupArtistConnection', foreign_key: 'group_id', dependent: :destroy
    has_many :artists, class_name: 'MusicArtist', through: :artist_connections
    has_many :releases, class_name: 'MusicRelease', through: :artists
    has_many :videos, class_name: 'MusicVideo', through: :artists
    
    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validate :registered_on_lastfm
    
    attr_accessible :name, :artist_connections_text
    
    attr_accessor :artist_connections_text
    
    def import_artist_connections
      artist_names_without_mbid = []
      artist_names = artist_connections_text.split("\n").map(&:strip)
      
      artist_names.each do |artist_name|
        lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
        lastfm_artist = lastfm.artist.get_info(artist: artist_name)
        
        if lastfm_artist['mbid'].blank?
          artist_names_without_mbid << lastfm_artist['name']
          
          next
        end
        
        artist = MusicArtist.where(mbid: lastfm_artist['mbid']).first
        
        unless artist
          musicbrainz_artist = MusicBrainz::Artist.find(lastfm_artist['mbid'])
          
          if musicbrainz_artist
            artist = MusicArtist.where(mbid: musicbrainz_artist.id).first
            artist = MusicArtist.create(name: lastfm_artist['name'], mbid: musicbrainz_artist.id) unless artist
          end
        end
        
        next unless artist
        
        if artist_connections.where(artist_id: artist.id).none?
          MusicMetadataEnrichment::GroupArtistConnection.create(group_id: id, artist_id: artist.id)
        end
      end
      
      artist_names_without_mbid
    end
    
    private
    
    def registered_on_lastfm
      return if name.blank?
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      
      begin
        lastfm.group.get_members(group: name)
      rescue Lastfm::ApiError
        errors[:name] << I18n.t('activerecord.errors.models.music_metadata_enrichment_group.attributes.name.not_registered_on_lastfm')
      end
    end
  end
end