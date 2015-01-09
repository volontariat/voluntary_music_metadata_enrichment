module MusicMetadataEnrichment
  module BaseController
    extend ActiveSupport::Concern
      
    def application_navigation
      :main_music_metadata_enrichment
    end
    
    def navigation_product_path
      music_metadata_enrichment_product_path
    end
    
    def navigation_product_name
      'Music Metadata Enrichment'
    end
  end
end