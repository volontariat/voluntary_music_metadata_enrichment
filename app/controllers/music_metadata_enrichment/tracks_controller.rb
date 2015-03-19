# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::TracksController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  include ::MusicMetadataEnrichment::TrackConfirmation
  
  authorize_resource class: 'MusicTrack', except: [:by_name]
  
  def index
  end
  
  def autocomplete
    artist = MusicArtist.find(params[:artist_id])
    render json: (
      artist.tracks.without_slaves.select('id, name').where("LOWER(name) LIKE ?", "#{params[:term].to_s.strip.downcase}%").order(:name).limit(10).map{|r| { id: r.id, value: r.name } }
    ), root: false
  end
  
  def new
    build_artist
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def artist_confirmation
    confirm_artist('new_track')
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def select_artist
    artist_selection('new_track')
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def name
    build_track
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def name_confirmation
    build_track
    @tracks = MusicTrack.search_on_musicbrainz(@track.artist.mbid, @track.name)
    
    if @tracks.none?
      track_creation('new_track', @track.name) 
      add_to_year_in_review_music_top_tracks if @track.persisted? && params[:year_in_review_music_id].present?
    else
      set_template_name_for_xhr_or_render
    end
    
    render_modal_javascript_response if request.xhr?
  end
  
  def create
    build_track
    track_creation('new_track')
    
    add_to_year_in_review_music_top_tracks if @track.persisted? && params[:year_in_review_music_id].present?
    
    render_modal_javascript_response if request.xhr?
  end
  
  def show
    @track = MusicTrack.find(params[:id])
    get_variables_for_show
  end
  
  def by_name
    if params[:artist_name].blank? || params[:name].blank?
      flash[:alert] = I18n.t('music_tracks.by_name.artist_name_or_name_blank')
      redirect_to music_tracks_path(artist_name: params[:artist_name], name: params[:name]) and return
    end
    
    @tracks = MusicTrack.by_artist_and_name(params[:artist_name], params[:name])
    @track = @tracks.first if params[:page].blank? && @tracks.count == 1
 
    if @track
      get_variables_for_show
      render :show
    else
      @tracks = MusicTrack.without_slaves.artist_and_name_like(params[:artist_name], params[:name]) if @tracks.nil? || @tracks.count == 0
      @tracks = @tracks.paginate(per_page: 10, page: params[:page] || 1)
    end
  end
  
  def resource
    @track
  end
  
  private
  
  def get_variables_for_show
    @videos = @track.videos.order_by_status
    @video_likes = MusicVideo.likes_or_dislikes_for(current_user, @videos.map(&:id)) unless !user_signed_in? || @videos.none?
    @year_in_review_music_tracks = @track.year_in_review_tops.published.group('position').count
  end
  
  def add_to_year_in_review_music_top_tracks
    year_in_review_music = current_user.years_in_review_music.where(id: params[:year_in_review_music_id]).first
    @path = create_user_music_year_in_review_top_track_path(year_in_review_music.user_id, year_in_review_music.year)
    @data = { year_in_review_music_track: { track_id: @track.id } }
    @method = :post
  end
end