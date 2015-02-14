class MusicMetadataEnrichment::GroupYearInReviewsController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  
  authorize_resource class: 'MusicMetadataEnrichment::GroupYearInReview'

  def index
    @group = MusicMetadataEnrichment::Group.find(params[:group_id])
    @years_in_review = @group.year_in_reviews.order('year DESC').paginate(per_page: 10, page: params[:page] || 1)
      
    render layout: false if request.xhr?
  end
  
  def show
    @group = MusicMetadataEnrichment::Group.find(params[:group_id])
    @year_in_review = @group.year_in_reviews.where(year: params[:year]).first
  end
end