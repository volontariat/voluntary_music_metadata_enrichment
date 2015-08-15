module MusicMetadataEnrichment
  module ArtistConfirmation
    extend ActiveSupport::Concern
    
    included do
      helper_method :render_modal_javascript_response
    end
    
    def confirm_artist(from)
      build_artist
  
      if @artist.mbid.present?
        musicbrainz_artist = MusicBrainz::Artist.find(@artist.mbid)
        
        if musicbrainz_artist
          @artist.mbid = musicbrainz_artist.id
          @artist.name = musicbrainz_artist.name
          artist = MusicArtist.where(mbid: @artist.mbid).first
          
          if artist
            @artist = artist
          else
            @artist.save
            
            if from == 'new_artist'
              flash[:notice] = I18n.t('music_artists.name_confirmation.scheduled_metadata_import')
            elsif ['new_release', 'new_track', 'new_video'].include?(from)
              flash[:notice] = I18n.t('music_releases.artist_confirmation.artist_import_scheduled')
            end
          end
          
          redirect_after_artist_available(from)
        else
          flash[:alert] = I18n.t('music_artists.new.mbid_invalid')
          
          if from == 'new_artist'
            if params[:user_id].present?
              @path = new_user_music_library_artist_path(params[:user_id])
            else
              @path = new_music_artist_path
            end
          elsif from == 'new_release'
            if params[:group_id].present?
              @path = new_music_group_release_path(params[:group_id])
            else
              @path = new_music_release_path
            end
          elsif from == 'new_track'
            @path = new_music_track_path
          elsif from == 'new_video'
            if params[:group_id].present?
              new_music_group_video_path(params[:group_id])
            else
              @path = new_music_video_path
            end
          elsif from == 'new_group_artist_connection'
            @path = new_music_group_artist_path(params[:group_id])
          end
        end
      elsif @artist.name.present?
        @artists = MusicBrainz::Artist.search(@artist.name)
      else
        @template = :new
      end
      
      if @template.present? && !request.xhr?
        render @template
      elsif @path.present? && !request.xhr?
        redirect_to @path
      end
    end
  
    def create_artist(from, name_and_mbid, artist_not_found = false)
      @artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first unless artist_not_found
      
      unless @artist
        @artist = MusicArtist.create(name: name_and_mbid.split(';').first, mbid: name_and_mbid.split(';').last)
        
        if @artist.persisted?
          if from == 'new_artist'
            flash[:notice] = I18n.t('music_artists.create.scheduled_artist_for_import')
          elsif ['new_release', 'new_track', 'new_video'].include? from
            flash[:notice] = I18n.t('music_releases.select_artist.scheduled_artist_for_import')
          end
        else
          params[:music_artist][:name] = @artist.name
          params[:music_artist][:mbid] = @artist.mbid
        end
      end
    end
    
    def artist_selection(from)
      params[:music_artist] ||= {}
      name_and_mbid = params[:music_artist].delete(:name_and_mbid)
      @artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first
      create_artist(from, name_and_mbid, true) unless @artist
      redirect_after_artist_available(from)
    end
    
    def build_artist
      params[:music_artist] ||= {}
      @artist = MusicArtist.new
      @artist.name = params[:music_artist][:name]
      @artist.mbid = params[:music_artist][:mbid]
    end
    
    def redirect_after_artist_available(from)
      if !@artist.persisted?
        render :new
      elsif ['new_artist', 'new_release', 'new_track', 'new_video'].include?(from) # && @artist.active?
        working_params = {}
        
        if params[:group_id].present?
          MusicMetadataEnrichment::GroupArtistConnection.create(group_id: params[:group_id], artist_id: @artist.id)
          working_params[:group_id] = params[:group_id]
        elsif params[:user_id].present?
          user_id = params[:user_id].match(/\D/) ? User.where('LOWER(slug) = ?', params[:user_id].downcase).first.id : params[:user_id]
          MusicLibraryArtist.create(user_id: user_id, artist_id: @artist.id)
        end
          
        case from
        when 'new_release'
          if @artist.is_classic?
            flash[:alert] = I18n.t('music_releases.artist_confirmation.classical_releases_not_supported')
            
            @path = params[:group_id].present? ? music_group_path(params[:group_id]) : music_path  
          else
            @path = name_music_releases_path(working_params.merge(music_release: { artist_id: @artist.id }))
          end
        when 'new_track' then 
          @path = name_music_tracks_path(music_track: { artist_id: @artist.id })
        when 'new_video'
          @path = track_name_music_videos_path(working_params.merge(music_track: { artist_id: @artist.id }))
        else
          if params[:group_id].present?
            @path = music_group_path(params[:group_id])
          elsif params[:user_id].present?
            @path = user_music_library_path(params[:user_id])
          else
            @path = music_path
          end
        end
      elsif from == 'new_group_artist_connection'
        @path = creation_music_group_artists_path(
          group_artist_connection: { group_id: params[:group_id], artist_id: @artist.id }
        )
      end
      
      redirect_to @path unless @path.blank? || request.xhr?
    end
    
    def set_template_name_for_xhr_or_render
      if @template.present? && !request.xhr?
        render @template
      elsif @template.blank? && @path.blank?
        @template = action_name
      end
    end
    
    def render_modal_javascript_response
      @data ||= { year_in_review_music_id: params[:year_in_review_music_id] }
      @method ||= :get
      render(
        partial: 'shared/modal_javascript_response.js', 
        locals: { 
          title: t("year_in_review_music_#{controller_name}.new.new_#{controller_name.singularize}"), 
          namespace: "music_metadata_enrichment/#{controller_name}/",
          ajax_data: @data, ajax_method: @method
        },
        layout: false
      )
    end
  end
end