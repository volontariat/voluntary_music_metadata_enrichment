class Product::MusicMetadataEnrichmentController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  
  def index
    MusicRelease.find(190).set_spotify_album_id
    raise 'done'
  end
end