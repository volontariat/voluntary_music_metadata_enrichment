module MusicMetadataEnrichment
  module TrackConfirmation
    extend ActiveSupport::Concern
    
    private
    
    def track_creation(from)
      name_and_mbid = params[:music_track].delete(:name_and_mbid)
      @track.name = MusicTrack.format_name(name_and_mbid.split(';').first)
      
      if @track.name.length > 255
        flash[:alert] = I18n.t('errors.messages.too_long.other', count: 255)
        
        if params[:group_id].present?
          redirect_to music_group_path(params[:group_id])
        else
          redirect_to music_path
        end
      elsif track = MusicTrack.where("artist_id = :artist_id AND LOWER(name) = :name", artist_id: @track.artist_id, name: @track.name.downcase.strip).first
        if from == 'new_track'
          flash[:alert] = I18n.t('music_tracks.create.already_exist')
          redirect_to music_track_path(track.id)
        elsif from == 'new_video'
          redirect_to metadata_music_videos_path(
            (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_video: { track_id: track.id })
          ) 
        end
      else
        if @track.artist.is_classical? || @track.is_bonus_track?
          @track.create_bonus_track(name_and_mbid.split(';').last)
          flash[:notice] = I18n.t('music_tracks.create.successfully_creation')
          
          if from == 'new_track'
            redirect_to music_track_path(@track.id)
          elsif from == 'new_video'
            redirect_to metadata_music_videos_path(
              (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_video: { track_id: @track.id })
            ) 
          end
        elsif @track.release_name.present?
          release = MusicRelease.create(artist_id: @track.artist_id, name: @track.release_name)
          
          if release.valid?
            flash[:notice] = I18n.t('music_tracks.create.scheduled_release_for_import')
          else
            flash[:alert] = release.errors.full_messages.join('. ')
          end
          
          if params[:group_id].present?
            redirect_to music_group_path(params[:group_id])
          else
            redirect_to music_path
          end
        end
      end
    end
    
    def build_track
      params[:music_track] ||= {}
      @track = MusicTrack.new
      @track.name = MusicTrack.format_name(params[:music_track][:name]) if params[:music_track][:name].present?
      @track.artist_id = params[:music_track][:artist_id]
    end
  end
end