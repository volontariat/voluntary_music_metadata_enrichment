class MusicMetadataEnrichment::ReleasesController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  
  def show
    @release = MusicRelease.find(params[:id])
    @tracks = @release.tracks.order('nr ASC')
  end
  
  def resource
    @release
  end
end