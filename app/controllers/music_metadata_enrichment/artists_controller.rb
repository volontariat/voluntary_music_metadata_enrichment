class MusicMetadataEnrichment::ArtistsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  
  def index
  end
  
  def new
    build_artist
  end
  
  def name_confirmation
    build_artist

    if @artist.mbid.present?
      musicbrainz_artist = MusicBrainz::Artist.find(@artist.mbid)
      
      if musicbrainz_artist
        flash[:notice] = 'Successfully scheduled music artist for metadata import.'
        @artist.name = musicbrainz_artist.name
        @artist.save
        redirect_to music_metadata_enrichment_artists_path
      else
        flash[:alert] = 'MBID is invalid.'
        redirect_to new_music_metadata_enrichment_artist_path
      end
    elsif @artist.name.present?
      @artists = MusicBrainz::Artist.search(@artist.name)
    else
      render :new
    end
  end
  
  def create
    params[:music_artist] ||= {}
    name_and_mbid = params[:music_artist].delete(:name_and_mbid)
    @artist = MusicArtist.create(name: name_and_mbid.split(';').first, mbid: name_and_mbid.split(';').last)
    
    if @artist.valid?
      flash[:notice] = 'Successfully scheduled music artist for metadata import.'
      redirect_to music_metadata_enrichment_artists_path
    else
      params[:music_artist][:name] = @artist.name
      params[:music_artist][:mbid] = @artist.mbid
      render :new
    end
  end
  
  def show
    @artist = MusicArtist.find(params[:id])
    @releases = @artist.releases.order('released_at ASC')
  end
  
  def resource
    @artist
  end
  
  private
  
  def build_artist
    params[:music_artist] ||= {}
    @artist = MusicArtist.new
    @artist.name = params[:music_artist][:name]
    @artist.mbid = params[:music_artist][:mbid]
  end
end