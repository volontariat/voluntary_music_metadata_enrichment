class MusicMetadataEnrichment::GroupYearInReviewTracksController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  authorize_resource class: 'MusicMetadataEnrichment::GroupYearInReviewTrack', except: [:export]
  
  def index
    @group = MusicMetadataEnrichment::Group.find(params[:group_id])
    find_collection
    
    render partial: 'library/music/year_in_review_tracks/collection' if request.xhr?
  end
  
  def export
    @group = MusicMetadataEnrichment::Group.find(params[:group_id])
    find_collection
    
    render template: 'library/music/year_in_review_tracks/export', layout: false
  end
  
  private
  
  def find_collection
    @year_in_review = @group.year_in_reviews.where(year: params[:year]).first
    @year_in_review_tracks = @year_in_review.tracks.order('position ASC')
  end
end