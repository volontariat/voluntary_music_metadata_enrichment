class Library::Music::YearInReviewTracksController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  authorize_resource class: 'YearInReviewMusicTrack', except: [:move]
  
  def index
    @user = User.find(params[:user_id])
    find_year_in_review
    
    if request.xhr?
      get_year_in_review_tracks
      render partial: 'library/music/year_in_review_tracks/collection'
    end
  end
  
  def new
    build_resource
    render layout: false
  end
  
  def create
    build_resource
    
    if @year_in_review_track.save
      MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_track.artist_id)
      @notice = I18n.t('year_in_review_music_tracks.create.successful') 
      get_year_in_review_tracks
    end
    
    render layout: false
  end
  
  def move
    @year_in_review_track = YearInReviewMusicTrack.find(params[:id])
    
    authorize! :move, @year_in_review_track
    
    @year_in_review_track.insert_at(params[:position].to_i)
    
    render nothing: true
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
  
  def get_year_in_review_tracks
    @year_in_review_tracks = @year_in_review.tracks.order('position ASC')
  end
end