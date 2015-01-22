class Library::MusicController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  def index
    @year = Time.now.strftime('%Y')
    @releases = User.find(params[:user_id]).music_releases.released_in_year(@year).order('released_at DESC')
  end
  
  def resource
    nil
  end
end