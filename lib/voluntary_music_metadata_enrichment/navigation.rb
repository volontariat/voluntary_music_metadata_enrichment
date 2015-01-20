module VoluntaryMusicMetadataEnrichment
  module Navigation
    def self.code
      Proc.new do |navigation|
        navigation.items do |primary|
          primary.dom_class = 'nav'
          
          primary.item :music_metadata_enrichment_groups, I18n.t('music_metadata_enrichment_groups.index.short_title'), music_metadata_enrichment_groups_path do |groups|
            groups.item :new, I18n.t('general.new'), new_music_metadata_enrichment_group_path
          end
                    
          primary.item :music_metadata_enrichment_artists, I18n.t('music_artists.index.short_title'), music_metadata_enrichment_artists_path do |artists|
            artists.item :new, I18n.t('general.new'), new_music_metadata_enrichment_artist_path
          end
          
          primary.item :music_metadata_enrichment_releases, I18n.t('music_releases.index.short_title'), music_metadata_enrichment_releases_path do |releases|
            releases.item :new, I18n.t('general.new'), new_music_metadata_enrichment_release_path
          end
          
          primary.item :music_metadata_enrichment_tracks, I18n.t('music_tracks.index.short_title'), music_metadata_enrichment_tracks_path do |tracks|
            tracks.item :new, I18n.t('general.new'), new_music_metadata_enrichment_track_path
          end

          primary.item :music_metadata_enrichment_videos, I18n.t('music_videos.index.short_title'), music_metadata_enrichment_videos_path do |videos|
            videos.item :new, I18n.t('general.new'), new_music_metadata_enrichment_video_path
          end
          
          instance_exec primary, ::Voluntary::Navigation::Base.menu_options(:authentication), &::Voluntary::Navigation.menu_code(:authentication)
        end
      end
    end
  end
end
    