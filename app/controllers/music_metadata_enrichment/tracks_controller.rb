# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::TracksController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
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
  end
  
  def artist_confirmation
    confirm_artist('new_track')
  end
  
  def select_artist
    artist_selection('new_track')
  end
  
  def name
    build_track
  end
  
  def name_confirmation
    build_track
    
    @tracks = MusicTrack.search_on_musicbrainz(@track.artist.mbid, @track.name)
  end
  
  def create
    build_track
    track_creation('new_track')
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
    
    unless @videos.none?
      @video_likes = current_user.likes_or_dislikes.for_targets('MusicVideo', @videos.map(&:id)).index_by(&:target_id)
    end
  end
end