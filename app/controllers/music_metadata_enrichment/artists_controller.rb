class MusicMetadataEnrichment::ArtistsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  def index
  end
  
  def new
    build_artist
  end
  
  def name_confirmation
    confirm_artist('new_artist')
  end
  
  def create
    params[:music_artist] ||= {}
    name_and_mbid = params[:music_artist].delete(:name_and_mbid)
    create_artist('new_artist', name_and_mbid)
  end
  
  def show
    @artist = MusicArtist.find(params[:id])
    @releases = @artist.releases.order('released_at ASC')
  end
  
  def resource
    @artist
  end
end