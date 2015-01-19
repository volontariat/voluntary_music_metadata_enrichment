# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::TracksController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  def index
  end
  
  def new
    build_artist
  end
  
  def artist_confirmation
    confirm_artist('new_track')
  end
  
  def select_artist
    artist_selection('new_track')
  end
  
  def name
    build_track
  end
  
  def name_confirmation
    build_track
    
    @tracks = MusicTrack.search_on_musicbrainz(@track.artist.mbid, @track.name)
  end
  
  def create
    build_track
    track_creation('new_track')
  end
  
  def show
    @track = MusicTrack.find(params[:id])
    @videos = @track.videos.order_by_status
  end
  
  def by_name
    track = MusicTrack.without_slaves.where(
      "LOWER(artist_name) = :artist_name AND LOWER(name) = :name", 
      artist_name: params[:artist_name].downcase.strip, name: params[:name].downcase.strip
    ).first
    
    if track
      redirect_to music_metadata_enrichment_track_path(track.id)
    else
      @tracks = MusicTrack.without_slaves.artist_and_name_like(params[:artist_name], params[:name]).limit(10)
    end
  end
  
  def resource
    @track
  end
end