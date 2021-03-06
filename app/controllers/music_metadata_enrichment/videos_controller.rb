# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::VideosController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  include ::MusicMetadataEnrichment::TrackConfirmation
    
  authorize_resource class: 'MusicVideo', except: [:by_name]
    
  def index
    if request.xhr? 

      if params[:artist_id].present?
        @videos = MusicVideo.where(artist_id: params[:artist_id])
      elsif params[:group_id].present?
        @videos = MusicMetadataEnrichment::Group.find(params[:group_id]).videos
      elsif params[:uploaded_by_the_user] == 'true'
        @videos = MusicVideo.where(user_id: current_user.id)
      elsif params[:user_id].present?
        @videos = User.by_slug_or_id(params[:user_id]).music_videos
      end
      
      @videos = @videos.order('created_at DESC').paginate(per_page: 5, page: params[:page] || 1)
      @video_likes = MusicVideo.likes_or_dislikes_for(current_user, @videos.map(&:id)) unless !user_signed_in? || @videos.none?
      
      render partial: 'music_metadata_enrichment/videos/collection', locals: { paginate: true }
    end
  end
  
  def new
    if params[:artist_id].present?
      redirect_to track_name_music_videos_path(music_track: { artist_id: params[:artist_id]})
    elsif params[:track_id].present?
      redirect_to metadata_music_videos_path(music_video: { track_id: params[:track_id]})  
    else
      build_artist
    end
  end
  
  def artist_confirmation
    confirm_artist('new_video')
  end
  
  def select_artist
    artist_selection('new_video')
  end
  
  def track_name
    build_track
  end
  
  def track_confirmation
    build_track
    
    @tracks = MusicTrack.search_on_musicbrainz(@track.artist.mbid, @track.name)
    
    track_creation('new_video', @track.name) if @tracks.none?
  end
  
  def create_track
    build_track
    track_creation('new_video')
  end
  
  def metadata
    build_video
  end
  
  def create
    build_video
    
    if @video.save
      flash[:notice] = I18n.t('music_videos.create.successful')
      
      if params[:group_id].present?
        redirect_to music_group_path(params[:group_id])
      else
        redirect_to music_video_path(@video)
      end
    else
      render :metadata
    end
  end
  
  def show
    @video = MusicVideo.find(params[:id])
    @video_likes = MusicVideo.likes_or_dislikes_for(current_user, [@video.id]) if user_signed_in?
  end
  
  def by_name
    if params[:artist_name].blank? || params[:name].blank?
      flash[:alert] = I18n.t('music_videos.by_name.artist_name_or_name_blank')
      redirect_to music_videos_path(artist_name: params[:artist_name], name: params[:name]) and return
    end
     
    status = if match = params[:name].match(/\(Live\)|\(Official\)|\(Unofficial\)/i)
      match[0].gsub(/\(|\)/, '').titleize
    else
      nil
    end
    
    name = params[:name].gsub(/\(Live\)|\(Official\)|\(Unofficial\)/i, '')
    
    unless params[:page].present?
      @videos = MusicVideo.by_artist_and_name(params[:artist_name], name)
      @videos = @videos.where(status: status) if status.present?
      
      @video = @videos.first if @videos.count == 1
    end
    
    if @video
      redirect_to music_video_path(@video)
    else
      if @videos.count == 0
        @videos = MusicVideo.artist_and_name_like(params[:artist_name], name)
        @videos = @videos.where(status: status) if status.present?
      end
      
      @videos = @videos.paginate(per_page: 10, page: params[:page] || 1)
      @video_likes = MusicVideo.likes_or_dislikes_for(current_user, @videos.map(&:id)) unless !user_signed_in? || @videos.none?
    end
  end
  
  def resource
    @video
  end
  
  private
  
  def build_video
    @video = MusicVideo.new(params[:music_video])
    @video.user_id = current_user.id
  end
end