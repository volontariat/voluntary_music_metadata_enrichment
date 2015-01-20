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
    @releases = @artist.releases.order('released_at ASC')
  end
  
  def by_name
    artist = MusicArtist.where("LOWER(name) = ?", params[:name].downcase.strip).first
    
    if artist
      redirect_to music_metadata_enrichment_artist_path(artist.id)
    else
      artists_table = MusicArtist.arel_table
      @artists = MusicArtist.where(artists_table[:name].matches("%#{params[:name]}%")).limit(10)
    end
  end
  
  def resource
    @artist
  end
end