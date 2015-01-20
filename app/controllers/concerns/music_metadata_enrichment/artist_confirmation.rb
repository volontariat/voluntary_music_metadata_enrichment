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
          
          if ['new_release', 'new_track', 'new_video'].include?(from) && (artist = MusicArtist.where(mbid: @artist.mbid).first) && artist.active?
            case from
            when 'new_release' then redirect_to name_music_metadata_enrichment_releases_path(music_release: { artist_id: artist.id })
            when 'new_track' then redirect_to name_music_metadata_enrichment_tracks_path(music_track: { artist_id: artist.id })
            when 'new_video' then redirect_to track_name_music_metadata_enrichment_tracks_path(music_track: { artist_id: artist.id })
            end
          elsif artist && from == 'new_group_artist_connection'
            redirect_to creation_music_metadata_enrichment_group_artists_path(
              group_artist_connection: { group_id: params[:group_id], artist_id: artist.id }
            )
          elsif artist
            flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
            redirect_to music_metadata_enrichment_path 
          elsif @artist.save
            if from == 'new_artist'
              flash[:notice] = I18n.t('music_artists.name_confirmation.scheduled_metadata_import')
            elsif ['new_release', 'new_track', 'new_video'].include?(from)
              flash[:notice] = I18n.t('music_releases.artist_confirmation.artist_import_scheduled')
            end
            
            if ['new_artist', 'new_release', 'new_track', 'new_video'].include?(from)
              redirect_to music_metadata_enrichment_path
            elsif from == 'new_group_artist_connection'
              redirect_to creation_music_metadata_enrichment_group_artists_path(
                group_artist_connection: { group_id: params[:group_id], artist_id: @artist.id }
              )
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
          elsif from == 'new_track'
            redirect_to new_music_metadata_enrichment_track_path
          elsif from == 'new_video'
            redirect_to new_music_metadata_enrichment_video_path
          elsif from == 'new_group_artist_connection'
            redirect_to new_music_metadata_enrichment_group_artist_path
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
        elsif ['new_release', 'new_track', 'new_video'].include? from
          flash[:notice] = I18n.t('music_releases.select_artist.scheduled_artist_for_import')
        end
        
        if ['new_artist', 'new_release', 'new_track', 'new_video'].include? from
          redirect_to music_metadata_enrichment_path
        elsif from == 'new_group_artist_connection'
          redirect_to creation_music_metadata_enrichment_group_artists_path(
            group_artist_connection: { group_id: params[:group_id], artist_id: @artist.id }
          )
        end
      else
        params[:music_artist][:name] = @artist.name
        params[:music_artist][:mbid] = @artist.mbid
        render :new
      end
    end
    
    def artist_selection(from)
      params[:music_artist] ||= {}
      name_and_mbid = params[:music_artist].delete(:name_and_mbid)
      artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first
   
      if artist && from == 'new_group_artist_connection'
        redirect_to creation_music_metadata_enrichment_group_artists_path(
          group_artist_connection: { group_id: params[:group_id], artist_id: artist.id }
        )
      elsif artist && artist.active?
        if from == 'new_release'
          redirect_to name_music_metadata_enrichment_releases_path(music_release: { artist_id: artist.id })
        elsif from == 'new_track'
          redirect_to name_music_metadata_enrichment_tracks_path(music_track: { artist_id: artist.id })
        elsif from == 'new_video'
          redirect_to track_name_music_metadata_enrichment_videos_path(music_track: { artist_id: artist.id })
        end
      elsif artist
        flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
        redirect_to music_metadata_enrichment_path 
      else
        create_artist(from, name_and_mbid)
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