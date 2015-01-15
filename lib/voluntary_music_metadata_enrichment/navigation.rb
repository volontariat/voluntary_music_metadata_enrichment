module VoluntaryMusicMetadataEnrichment
  module Navigation
    def self.code
      Proc.new do |navigation|
        navigation.items do |primary|
          primary.dom_class = 'nav'
          
          primary.item :music_metadata_enrichment_artists, I18n.t('music_artists.index.short_title'), music_metadata_enrichment_artists_path do |artists|
            artists.item :new, I18n.t('general.new'), new_music_metadata_enrichment_artist_path
          end
          
          primary.item :music_metadata_enrichment_releases, I18n.t('music_releases.index.short_title'), music_metadata_enrichment_releases_path do |releases|
            releases.item :new, I18n.t('general.new'), new_music_metadata_enrichment_release_path
          end
          
          if user_signed_in?
            primary.item :workflow, I18n.t('workflow.index.title'), music_metadata_enrichment_workflow_path do |workflow|
            end
          end
          
          instance_exec primary, ::Voluntary::Navigation::Base.menu_options(:authentication), &::Voluntary::Navigation.menu_code(:authentication)
        end
      end
    end
  end
end
    