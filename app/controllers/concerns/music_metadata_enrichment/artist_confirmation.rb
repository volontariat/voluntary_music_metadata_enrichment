module MusicMetadataEnrichment
  module ArtistConfirmation
    extend ActiveSupport::Concern
  
    def confirm_artist(from)
      build_artist
  
      if @artist.mbid.present?
        musicbrainz_artist = MusicBrainz::Artist.find(@artist.mbid)
        
        if musicbrainz_artist
          @artist.name = musicbrainz_artist.name
          artist = nil
          
          if from == 'new_release' && (artist = MusicArtist.where(mbid: @artist.mbid).first) && artist.active?
            redirect_to name_music_metadata_enrichment_releases_path(music_release: { artist_id: artist.id })
          elsif artist
            flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
            redirect_to music_metadata_enrichment_releases_path 
          elsif @artist.save
            if from == 'new_artist'
              flash[:notice] = I18n.t('music_artists.name_confirmation.scheduled_metadata_import')
              redirect_to music_metadata_enrichment_artists_path
            elsif from == 'new_release'
              flash[:notice] = I18n.t('music_releases.artist_confirmation.artist_import_scheduled')
              redirect_to music_metadata_enrichment_releases_path
            end
          else
            render :new
          end
        else
          flash[:alert] = I18n.t('music_artists.new.mbid_invalid')
          
          if from == 'new_artist'
            redirect_to new_music_metadata_enrichment_artist_path
          elsif from == 'new_release'
            redirect_to new_music_metadata_enrichment_release_path
          end
        end
      elsif @artist.name.present?
        @artists = MusicBrainz::Artist.search(@artist.name)
      else
        render :new
      end
    end
    
    def create_artist(from, name_and_mbid)
      @artist = MusicArtist.create(name: name_and_mbid.split(';').first, mbid: name_and_mbid.split(';').last)
      
      if @artist.valid?
        if from == 'new_artist'
          flash[:notice] = I18n.t('music_artists.create.scheduled_artist_for_import')
          redirect_to music_metadata_enrichment_artists_path
        elsif from == 'new_release'
          flash[:notice] = I18n.t('music_releases.select_artist.scheduled_artist_for_import')
          redirect_to music_metadata_enrichment_releases_path
        end
      else
        params[:music_artist][:name] = @artist.name
        params[:music_artist][:mbid] = @artist.mbid
        render :new
      end
    end
    
    private
    
    def build_artist
      params[:music_artist] ||= {}
      @artist = MusicArtist.new
      @artist.name = params[:music_artist][:name]
      @artist.mbid = params[:music_artist][:mbid]
    end
  end
end