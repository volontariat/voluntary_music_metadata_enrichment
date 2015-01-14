module VoluntaryMusicMetadataEnrichment
  class Engine < ::Rails::Engine
    config.autoload_paths << File.expand_path("../../../app/models/concerns", __FILE__)
    config.autoload_paths << File.expand_path("../../../app/controllers/concerns", __FILE__)
    config.i18n.load_path += Dir[File.expand_path("../../../config/locales/**/*.{rb,yml}", __FILE__)]
    
    SimpleNavigation::config_file_paths << File.expand_path("../../../config", __FILE__)
    
    config.generators do |g|
      g.orm :active_record
    end
    
    config.to_prepare do
      User.send :include, ::VoluntaryMusicMetadataEnrichment::Concerns::Model::User::HasMusicLibrary
      ::Ability.add_after_initialize_callback(VoluntaryMusicMetadataEnrichment::Ability.after_initialize)
    end
  end
end
