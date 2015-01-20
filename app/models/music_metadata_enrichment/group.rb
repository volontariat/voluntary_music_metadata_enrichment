module MusicMetadataEnrichment
  class Group < ActiveRecord::Base
    self.table_name = 'music_metadata_enrichment_groups'
    
    validates :name, presence: true, uniqueness: true
    validate :registered_on_lastfm
    
    attr_accessible :name
    
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