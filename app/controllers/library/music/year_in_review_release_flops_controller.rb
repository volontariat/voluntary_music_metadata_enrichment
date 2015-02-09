class Library::Music::YearInReviewReleaseFlopsController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  before_action :find_resource, only: [:move, :destroy]
  authorize_resource class: 'YearInReviewMusicReleaseFlop'
  
  def create
    build_resource
    
    if @year_in_review_release_flop.save
      @year_in_review.releases.where(release_id: @year_in_review_release_flop.release_id).delete_all
      MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_release_flop.artist_id)
    end
    
    render layout: false
  end
  
  private
  
  def build_resource
    @user = current_user
    find_year_in_review
    params[:year_in_review_music_release_flop] ||= {}
    @year_in_review_release_flop = @year_in_review.flop_releases.new(release_id: params[:year_in_review_music_release_flop][:release_id])
  end
  
  def find_year_in_review
    @year_in_review = @user.years_in_review_music.where(year: params[:year]).first
  end
end