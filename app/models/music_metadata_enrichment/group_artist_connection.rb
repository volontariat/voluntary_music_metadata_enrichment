module MusicMetadataEnrichment
  class GroupArtistConnection < ActiveRecord::Base
    include Likeable
    
    self.table_name = 'music_metadata_enrichment_group_artist_connections'
    
    belongs_to :group, class_name: 'MusicMetadataEnrichment::Group'
    belongs_to :artist, class_name: 'MusicArtist'
    
    validates :group_id, presence: true
    validates :artist_id, presence: true, uniqueness: { scope: :group_id }
    
    attr_accessible :group_id, :artist_id
  end
end