module MusicMetadataEnrichment
  module ArtistConfirmation
    extend ActiveSupport::Concern
  
    private
    
    def confirm_artist(from)
      build_artist
  
      if @artist.mbid.present?
        musicbrainz_artist = MusicBrainz::Artist.find(@artist.mbid)
        
        if musicbrainz_artist
          @artist.mbid = musicbrainz_artist.id
          @artist.name = musicbrainz_artist.name
          artist = nil
          
          if ['new_release', 'new_track', 'new_video'].include?(from) && (artist = MusicArtist.where(mbid: @artist.mbid).first) && artist.active?
            working_params = {}
            
            if params[:group_id].present?
              MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: artist.id)
              working_params[:group_id] = params[:group_id]
            elsif params[:user_id].present?
              MusicLibraryArtist.create(user_id: params[:user_id], artist_id: artist.id)
            end
              
            case from
            when 'new_release' then redirect_to name_music_releases_path(working_params.merge(music_release: { artist_id: artist.id }))
            when 'new_track' then redirect_to name_music_tracks_path(music_track: { artist_id: artist.id })
            when 'new_video'
              redirect_to track_name_music_tracks_path(working_params.merge(music_track: { artist_id: artist.id }))
            end
          elsif artist && from == 'new_group_artist_connection'
            redirect_to creation_music_group_artists_path(
              group_artist_connection: { group_id: params[:group_id], artist_id: artist.id }
            )
          elsif artist
            flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
            
            if params[:group_id].present?
              MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: artist.id)
              redirect_to music_group_path(params[:group_id])
            elsif params[:user_id].present?
              MusicLibraryArtist.create(user_id: params[:user_id], artist_id: artist.id)
              redirect_to user_music_library_path(params[:user_id])
            else
              redirect_to music_path 
            end
          elsif @artist.save
            if from == 'new_artist'
              flash[:notice] = I18n.t('music_artists.name_confirmation.scheduled_metadata_import')
            elsif ['new_release', 'new_track', 'new_video'].include?(from)
              flash[:notice] = I18n.t('music_releases.artist_confirmation.artist_import_scheduled')
            end
            
            if params[:group_id].present?
              MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: @artist.id)
              redirect_to music_group_path(params[:group_id])
            elsif params[:user_id].present?
              MusicLibraryArtist.create(user_id: params[:user_id], artist_id: @artist.id)
              redirect_to user_music_library_path(params[:user_id])  
            elsif ['new_artist', 'new_release', 'new_track', 'new_video'].include?(from)
              redirect_to music_path
            elsif from == 'new_group_artist_connection'
              redirect_to creation_music_group_artists_path(
                group_artist_connection: { group_id: params[:group_id], artist_id: @artist.id }
              )
            end
          else
            render :new
          end
        else
          flash[:alert] = I18n.t('music_artists.new.mbid_invalid')
          
          if from == 'new_artist'
            if params[:user_id].present?
              redirect new_user_music_library_artist_path(params[:user_id])
            else
              redirect_to new_music_artist_path
            end
          elsif from == 'new_release'
            if params[:group_id].present?
              redirect_to new_music_group_release_path(params[:group_id])
            else
              redirect_to new_music_release_path
            end
          elsif from == 'new_track'
            redirect_to new_music_track_path
          elsif from == 'new_video'
            if params[:group_id].present?
              new_music_group_video_path(params[:group_id])
            else
              redirect_to new_music_video_path
            end
          elsif from == 'new_group_artist_connection'
            redirect_to new_music_group_artist_path(params[:group_id])
          end
        end
      elsif @artist.name.present?
        3.times do
          @artists = MusicBrainz::Artist.search(@artist.name)
          
          if @artists.nil?
            sleep 5
          else
            break
          end
        end
      else
        render :new
      end
    end
  
    def create_artist(from, name_and_mbid)
      @artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first
      
      if @artist
        if params[:group_id].present?
          flash[:notice] = I18n.t('music_artists.create.group_connection_successful')
          MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: @artist.id)
          redirect_to music_group_path(params[:group_id])
        elsif params[:user_id].present?
          flash[:notice] = I18n.t('music_artists.create.library_addition_successful')
          MusicLibraryArtist.create(user_id: params[:user_id], artist_id: @artist.id)
          redirect_to user_music_library_path(params[:user_id])  
        else
          flash[:notice] = I18n.t('music_artists.create.already_created')
          redirect_to music_artist_path(@artist.id)
        end
      else
        @artist = MusicArtist.create(name: name_and_mbid.split(';').first, mbid: name_and_mbid.split(';').last)
        
        if @artist.persisted?
          if from == 'new_artist'
            flash[:notice] = I18n.t('music_artists.create.scheduled_artist_for_import')
          elsif ['new_release', 'new_track', 'new_video'].include? from
            flash[:notice] = I18n.t('music_releases.select_artist.scheduled_artist_for_import')
          end
          
          if ['new_artist', 'new_release', 'new_track', 'new_video'].include? from
            if params[:group_id].present?
              MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: @artist.id)
              redirect_to music_group_path(params[:group_id])
            elsif params[:user_id].present?
              flash[:notice] = I18n.t('music_artists.create.library_addition_successful')
              MusicLibraryArtist.create(user_id: params[:user_id], artist_id: @artist.id)
              redirect_to user_music_library_path(params[:user_id])  
            else
              redirect_to music_path
            end
          elsif from == 'new_group_artist_connection'
            redirect_to creation_music_group_artists_path(
              group_artist_connection: { group_id: params[:group_id], artist_id: @artist.id }
            )
          end
        else
          params[:music_artist][:name] = @artist.name
          params[:music_artist][:mbid] = @artist.mbid
          render :new
        end
      end
    end
    
    def artist_selection(from)
      params[:music_artist] ||= {}
      name_and_mbid = params[:music_artist].delete(:name_and_mbid)
      artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first
   
      if artist && from == 'new_group_artist_connection'
        redirect_to creation_music_group_artists_path(
          group_artist_connection: { group_id: params[:group_id], artist_id: artist.id }
        )
      elsif artist && artist.active?
        if params[:group_id].present?
          MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: artist.id)
        end
          
        if from == 'new_release'
          redirect_to name_music_releases_path(
            (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_release: { artist_id: artist.id })
          )
        elsif from == 'new_track'
          redirect_to name_music_tracks_path(music_track: { artist_id: artist.id })
        elsif from == 'new_video'
          redirect_to track_name_music_videos_path(
            (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_track: { artist_id: artist.id })
          )
        end
      elsif artist
        flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
        
        if params[:group_id].present?
          MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: @artist.id)
          redirect_to music_group_path(params[:group_id])
        else
          redirect_to music_path 
        end
      else
        create_artist(from, name_and_mbid)
      end
    end
    
    def build_artist
      params[:music_artist] ||= {}
      @artist = MusicArtist.new
      @artist.name = params[:music_artist][:name]
      @artist.mbid = params[:music_artist][:mbid]
    end
  end
end