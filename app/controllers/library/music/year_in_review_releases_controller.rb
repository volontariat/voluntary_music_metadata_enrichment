class Library::Music::YearInReviewReleasesController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  authorize_resource class: 'YearInReviewMusicRelease', except: [:move]
  
  def index
    @user = User.find(params[:user_id])
    find_year_in_review
    
    if request.xhr?
      get_year_in_review_releases
      render partial: 'library/music/year_in_review_releases/collection'
    end
  end
  
  def new
    build_resource
    render layout: false
  end
  
  def create
    build_resource
    
    if @year_in_review_release.save
      @notice = I18n.t('year_in_review_music_releases.create.successful') 
      get_year_in_review_releases
    end
    
    render layout: false
  end
  
  def move
    @year_in_review_release = YearInReviewMusicRelease.find(params[:id])
    
    authorize! :move, @year_in_review_release
    
    @year_in_review_release.insert_at(params[:position].to_i)
    
    render nothing: true
  end
  
  private
  
  def find_year_in_review
    @year_in_review = @user.years_in_review_music.where(year: params[:year]).first
  end
  
  def build_resource
    @user = current_user
    find_year_in_review
    params[:year_in_review_music_release] ||= {}
    @year_in_review_release = @year_in_review.releases.new(release_id: params[:year_in_review_music_release][:release_id])
  end
  
  def get_year_in_review_releases
    @year_in_review_releases = @year_in_review.releases.order('position ASC')
  end
end