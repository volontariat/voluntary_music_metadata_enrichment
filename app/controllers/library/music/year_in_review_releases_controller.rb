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
  
  def multiple_new
    @user = current_user
    find_year_in_review
    @releases = current_user.music_releases.for_year_in_review(@year_in_review)
    @releases = @releases.where('music_releases.id > ?', params[:last_id]) if params[:last_id].present?
    @releases_left = @releases.count
    @releases = @releases.order('music_releases.id ASC').limit(10)
    params[:last_id] = params[:commit] == I18n.t('general.close') || @releases.none? ? nil : @releases.last.id

    if params[:commit] != I18n.t('general.close') && params[:year_in_review_music_releases].present?
      params[:year_in_review_music_releases].each do |release_id, checked|
        next unless checked == '1'
        
        @year_in_review_release = @year_in_review.releases.create(release_id: release_id)
        
        next unless @year_in_review_release.persisted?
        
        MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_release.artist_id)
      end
    end
    
    if params[:commit] == I18n.t('general.close') || @releases.none?
      get_year_in_review_releases
      params[:user_id] = current_user.id 
    end
    
    render layout: false
  end
  
  def create
    build_resource
    
    if @year_in_review_release.save
      MusicLibraryArtist.create(user_id: current_user.id, artist_id: @year_in_review_release.artist_id)
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