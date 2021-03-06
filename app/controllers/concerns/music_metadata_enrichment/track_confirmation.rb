module MusicMetadataEnrichment
  module TrackConfirmation
    extend ActiveSupport::Concern
    
    private
    
    def track_creation(from, name = nil)
      name_and_mbid = params[:music_track].delete(:name_and_mbid)
      @track.name = name || MusicTrack.format_name(name_and_mbid.split(';').first)
      
      if @track.name.length > 255
        flash[:alert] = I18n.t('errors.messages.too_long.other', count: 255)
        
        @path = params[:group_id].present? ? music_group_path(params[:group_id]) :
         music_path
      elsif track = MusicTrack.where("artist_id = :artist_id AND LOWER(name) = :name", artist_id: @track.artist_id, name: @track.name.downcase.strip).first
        @track = track
        @path = if from == 'new_track'
          flash[:alert] = I18n.t('music_tracks.create.already_exist')
          music_track_path(track.id)
        elsif from == 'new_video'
          metadata_music_videos_path(
            (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_video: { track_id: track.id })
          ) 
        end
      else
        is_bonus_track = name.present? ? false : @track.is_bonus_track?
        
        if @track.release_name.present?
          release = MusicRelease.create(artist_id: @track.artist_id, name: @track.release_name, is_lp: @track.release_is_lp)
        end
        
        if name.present? || @track.release_name.present?
          @track.create_draft_track(name || @track.name)
          
          if @track.persisted?
            flash[:notice] = I18n.t('music_tracks.create.draft_successful')
          else
            flash[:alert] = I18n.t('music_tracks.create.draft_failed', errors: @track.errors.full_messages.join('. '))
          end
        end  
          
        if name.blank? && (@track.artist.is_classic? || is_bonus_track)
          @track.create_bonus_track(name_and_mbid.split(';').last)
          
          if @track.persisted?
            flash[:notice] = I18n.t('music_tracks.create.bonus_track_successful')
          else
            flash[:alert] = I18n.t('music_tracks.create.bonus_track_failed', errors: @track.errors.full_messages.join('. '))
          end
        end
        
        if @track.persisted?  
          if from == 'new_track'
            @path = music_track_path(@track.id)
          elsif from == 'new_video'
            @path = metadata_music_videos_path(
              (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_video: { track_id: @track.id })
            ) 
          end
        else
          if ::MusicTrack.name_included_in_bonustrack_blacklist?(@track.name)
            flash[:alert] = I18n.t('music_tracks.create.name_included_in_bonustrack_blacklist')
          end
          
          @path = track_name_music_videos_path(
            (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(music_track: { artist_id: @track.artist_id })
          )
        end
      end
      
      redirect_to @path unless @path.blank? || request.xhr?
    end
    
    def build_track
      params[:music_track] ||= {}
      @track = MusicTrack.new
      @track.name = MusicTrack.format_name(params[:music_track][:name]) if params[:music_track][:name].present?
      @track.artist_id = params[:music_track][:artist_id]
    end
  end
end