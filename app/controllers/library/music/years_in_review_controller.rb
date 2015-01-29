class Library::Music::YearsInReviewController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  authorize_resource class: 'YearInReviewMusic'

  def index
    get_years_in_review
    build_year_in_review if user_signed_in?
      
    render layout: false if request.xhr?
  end
  
  def create
    build_year_in_review
    get_years_in_review
    @notice = I18n.t('years_in_review_music.create.successful') if @year_in_review.save
    render layout: false
  end
  
  def show
    @user = User.find(params[:user_id])
    @year_in_review = @user.years_in_review_music.where(year: params[:year]).first
  end
  
  def resource
    @year_in_review
  end
  
  private
  
  def build_year_in_review
    params[:year_in_review] ||= {}
    @year_in_review = current_user.years_in_review_music.new(year: params[:year_in_review][:year])
  end
  
  def get_years_in_review
    @user = User.find(params[:user_id])
    @years_in_review = @user.years_in_review_music.order('year DESC').paginate(per_page: 10, page: params[:page] || 1)
  end
end