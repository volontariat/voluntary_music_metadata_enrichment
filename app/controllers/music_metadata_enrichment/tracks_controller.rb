class MusicMetadataEnrichment::TracksController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  
  def show
    @track = MusicTrack.find(params[:id])
  end
  
  def resource
    @track
  end
end