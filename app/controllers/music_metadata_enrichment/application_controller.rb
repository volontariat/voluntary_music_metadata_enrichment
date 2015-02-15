class MusicMetadataEnrichment::ApplicationController < ::ApplicationController
  protected

  def voluntary_application_stylesheets
    ['voluntary/application', 'application'] 
  end

  def voluntary_application_javascripts
    ['voluntary/application', 'voluntary_music_metadata_enrichment/application', 'application'] 
  end
  
  def voluntary_application_repository_path
    'volontariat/voluntary_music_metadata_enrichment'
  end
end