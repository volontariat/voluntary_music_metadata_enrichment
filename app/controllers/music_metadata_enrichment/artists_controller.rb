class MusicMetadataEnrichment::ArtistsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  authorize_resource class: 'MusicArtist', except: [:by_name]
  
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
    get_variables_for_show
  end
  
  def by_name
    @artist = MusicArtist.where("LOWER(name) = ?", params[:name].downcase.strip).first unless params[:page].present?
    
    if @artist
      get_variables_for_show
      render :show
    else
      @artists = MusicArtist.name_like(params[:name]).paginate(per_page: 10, page: params[:page] || 1)
    end
  end
  
  def resource
    @artist
  end
  
  private
  
  def get_variables_for_show
    @releases = @artist.releases.order('released_at ASC')
  end
end