module MusicMetadataEnrichment
  module TrackConfirmation
    extend ActiveSupport::Concern
    
    private
    
    def track_creation(from)
      name_and_mbid = params[:music_track].delete(:name_and_mbid)
      @track.name = MusicTrack.format_name(name_and_mbid.split(';').first)
      
      if track = MusicTrack.where("artist_id = :artist_id AND LOWER(name) = :name", artist_id: @track.artist_id, name: @track.name.downcase.strip).first
        if from == 'new_track'
          flash[:alert] = I18n.t('music_tracks.create.already_exist')
          redirect_to music_metadata_enrichment_track_path(track.id)
        elsif from == 'new_video'
          redirect_to metadata_music_metadata_enrichment_videos_path(music_video: { track_id: track.id }) 
        end
      else
        if @track.is_bonus_track? #internally sets release_name
          @track.create_bonus_track(name_and_mbid.split(';').last)
          flash[:notice] = I18n.t('music_tracks.create.successfully_creation')
          
          if from == 'new_track'
            redirect_to music_metadata_enrichment_track_path(@track.id)
          elsif from == 'new_video'
            redirect_to metadata_music_metadata_enrichment_videos_path(music_video: { track_id: @track.id }) 
          end
        else
          release = MusicRelease.create(artist_id: @track.artist_id, name: @track.release_name)
          
          if release.valid?
            flash[:notice] = I18n.t('music_tracks.create.scheduled_release_for_import')
            redirect_to music_metadata_enrichment_path
          else
            flash[:alert] = release.errors.full_messages.join('. ')
            redirect_to music_metadata_enrichment_path
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