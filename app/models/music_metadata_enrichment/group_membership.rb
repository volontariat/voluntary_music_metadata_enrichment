module MusicMetadataEnrichment
  class GroupMembership < ActiveRecord::Base
    self.table_name = 'music_metadata_enrichment_group_memberships'
    
    belongs_to :group, class_name: 'MusicMetadataEnrichment::Group'
    belongs_to :user
    
    validates :group_id, presence: true
    validates :user_id, presence: true, uniqueness: { scope: :group_id }
    
    attr_accessible :group_id, :user_id
  end
end