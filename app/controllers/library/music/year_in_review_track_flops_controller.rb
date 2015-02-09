class Library::Music::YearInReviewTrackFlopsController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  before_action :find_resource, only: [:move, :destroy]
  authorize_resource class: 'YearInReviewMusicTrackFlop'
  
  def create
    build_resource
    
    if @year_in_review_track_flop.save
      @year_in_review.tracks.where(track_id: @year_in_review_track_flop.track_id).delete_all
      MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_track_flop.artist_id)
    end
    
    render layout: false
  end
  
  private
  
  def build_resource
    @user = current_user
    find_year_in_review
    params[:year_in_review_music_track_flop] ||= {}
    @year_in_review_track_flop = @year_in_review.flop_tracks.new(track_id: params[:year_in_review_music_track_flop][:track_id])
  end
  
  def find_year_in_review
    @year_in_review = @user.years_in_review_music.where(year: params[:year]).first
  end
end