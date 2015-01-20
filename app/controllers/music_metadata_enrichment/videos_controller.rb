# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::VideosController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  include ::MusicMetadataEnrichment::TrackConfirmation
    
  def index
  end
  
  def new
    build_artist
  end
  
  def artist_confirmation
    confirm_artist('new_video')
  end
  
  def select_artist
    artist_selection('new_video')
  end
  
  def track_name
    build_track
  end
  
  def track_confirmation
    build_track
    
    @tracks = MusicTrack.search_on_musicbrainz(@track.artist.mbid, @track.name)
  end
  
  def create_track
    build_track
    track_creation('new_video')
  end
  
  def metadata
    build_video
  end
  
  def create
    build_video
    
    if @video.save
      flash[:notice] = I18n.t('music_videos.create.successful')
      redirect_to music_metadata_enrichment_video_path(@video)
    else
      render :metadata
    end
  end
  
  def show
    @video = MusicVideo.find(params[:id])
  end
  
  def resource
    @video
  end
  
  private
  
  def build_video
    @video = MusicVideo.new(params[:music_video])
    @video.user_id = current_user.id
  end
end