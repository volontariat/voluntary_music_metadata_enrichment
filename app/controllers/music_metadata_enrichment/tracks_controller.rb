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
    params[:music_artist] ||= {}
    name_and_mbid = params[:music_artist].delete(:name_and_mbid)
    artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first
    
    if artist && artist.active?
      redirect_to name_music_metadata_enrichment_tracks_path(music_track: { artist_id: artist.id })
    elsif artist
      flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
      redirect_to music_metadata_enrichment_tracks_path 
    else
      create_artist('new_track', name_and_mbid)
    end
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
    name_and_mbid = params[:music_track].delete(:name_and_mbid)
    @track.name = name_and_mbid.split(';').first
    
    if track = MusicTrack.where("artist_id = :artist_id AND LOWER(name) = :name", artist_id: @track.artist_id, name: @track.name.downcase.strip).first
      flash[:alert] = I18n.t('music_tracks.create.already_exist')
      redirect_to music_metadata_enrichment_track_path(track.id)
    else
      if @track.is_bonus_track? #internally sets release_name
        @track.create_bonus_track(name_and_mbid.split(';').last)
        flash[:notice] = I18n.t('music_tracks.create.successfully_creation')
        redirect_to music_metadata_enrichment_track_path(@track.id)
      else
        release = MusicRelease.create(artist_id: @track.artist_id, name: @track.release_name)
        
        if release.valid?
          flash[:notice] = I18n.t('music_tracks.create.scheduled_release_for_import')
          redirect_to music_metadata_enrichment_path
        else
          flash[:alert] = release.errors.full_messages.join('. ')
          redirect_to music_metadata_enrichment_path
        end
      end
    end
  end
  
  def show
    @track = MusicTrack.find(params[:id])
  end
  
  def by_name
    track = MusicTrack.where(
      "LOWER(artist_name) = :artist_name AND LOWER(name) = :name", 
      artist_name: params[:artist_name].downcase.strip, name: params[:name].downcase.strip
    ).first
    
    if track
      redirect_to music_metadata_enrichment_track_path(track.id)
    else
      tracks_table = MusicTrack.arel_table
      @tracks = MusicTrack.where(tracks_table[:artist_name].matches("%#{params[:artist_name]}%").and(tracks_table[:name].matches("%#{params[:name]}%"))).limit(10)
    end
  end
  
  def resource
    @track
  end
  
  private
  
  def build_track
    params[:music_track] ||= {}
    @track = MusicTrack.new
    @track.name = params[:music_track][:name]
    @track.artist_id = params[:music_track][:artist_id]
  end
end