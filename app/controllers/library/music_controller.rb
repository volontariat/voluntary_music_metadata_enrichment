class Library::MusicController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  def index
    @year = Time.now.strftime('%Y')
    @user = User.by_slug_or_id(params[:user_id])
    @releases = @user.music_releases.released_in_year(@year).order('released_at DESC')
  end
  
  def resource
    nil
  end
end