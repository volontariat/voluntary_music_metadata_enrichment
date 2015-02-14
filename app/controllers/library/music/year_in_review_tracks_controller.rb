class Library::Music::YearInReviewTracksController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  before_action :find_resource, only: [:destroy]
  authorize_resource class: 'YearInReviewMusicTrack'
  
  def index
    @user = User.find(params[:user_id])
    find_year_in_review
    get_year_in_review_tracks
    
    render partial: 'library/music/year_in_review_tracks/collection' if request.xhr?
  end
  
  def new
    build_resource
    render layout: false
  end
  
  def multiple_new
    if params[:commit].present?
      @user = current_user
      find_year_in_review
      @tracks = current_user.music_tracks.for_year_in_review(@year_in_review)
      @release_ids = []
      
      if params[:only_tracks_of_top_releases] == 'true'
        @release_ids = @year_in_review.releases.map(&:release_id)
        @tracks = @tracks.where('music_tracks.release_id IN(?)', @release_ids) if @release_ids.any?
      end
      
      if params[:only_tracks_of_top_releases] == 'true' && @release_ids.none?
        @message = I18n.t('year_in_review_music_tracks.multiple_new.no_top_releases_available')
      else
        @tracks = @tracks.where('music_tracks.id > ?', params[:last_id]) if params[:last_id].present?
        @tracks_left = @tracks.count
        @tracks = @tracks.order('music_tracks.id ASC').limit(10)
        params[:last_id] = params[:commit] == I18n.t('general.close') || @tracks.none? ? nil : @tracks.last.id
        
        if params[:commit] != I18n.t('general.close') && params[:year_in_review_music_tracks].present?
          params[:year_in_review_music_tracks].each do |track_id, checked|
            next unless checked == '1'
            
            @year_in_review_track = @year_in_review.tracks.create(track_id: track_id)
            
            next unless @year_in_review_track.persisted?
            
            MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_track.artist_id)
          end
        end
        
        if params[:commit] == I18n.t('general.close') || @tracks.none?
          get_year_in_review_tracks
          params[:user_id] = current_user.id 
        end
      end
    end
    
    render layout: false
  end
  
  def create
    build_resource
    
    if @year_in_review_track.save
      @year_in_review.flop_tracks.where(track_id: @year_in_review_track.track_id).delete_all
      MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_track.artist_id)
      @notice = I18n.t('year_in_review_music_tracks.create.successful') 
      get_year_in_review_tracks
    end
    
    render layout: false
  end
  
  def move
    year_in_review_tracks = current_user.years_in_review_music_tracks.where('year_in_review_music_tracks.id IN(?)', params[:positions].keys).index_by(&:id)
  
    params[:positions].each do |id, position|
      year_in_review_tracks[id.to_i].reload
      year_in_review_tracks[id.to_i].insert_at(position.to_i)
    end
    
    render nothing: true
  end
  
  def destroy
    @year_in_review_track.destroy!
    @user = current_user
    params[:user_id], params[:year] = current_user.id, @year_in_review_track.year
    find_year_in_review
    get_year_in_review_tracks
    
    render layout: false
  end
  
  def export
    @user = current_user
    find_year_in_review
    get_year_in_review_tracks
    
    render layout: false
  end
  
  def resource
    @year_in_review_track
  end
  
  private
  
  def find_year_in_review
    @year_in_review = @user.years_in_review_music.where(year: params[:year]).first
  end
  
  def build_resource
    @user = current_user
    find_year_in_review
    params[:year_in_review_music_track] ||= {}
    @year_in_review_track = @year_in_review.tracks.new(track_id: params[:year_in_review_music_track][:track_id])
  end
  
  def find_resource
    @year_in_review_track = YearInReviewMusicTrack.find(params[:id])
  end
  
  def get_year_in_review_tracks
    @year_in_review_tracks = @year_in_review.tracks.order('position ASC')
  end
end