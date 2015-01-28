class Library::Music::ArtistsController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  before_action :find_resource, only: [:destroy]
  authorize_resource class: 'MusicLibraryArtist'
  
  def destroy
    @music_library_artist.destroy!
    @artists = User.find(@music_library_artist.user_id).music_artists.order('name ASC').paginate(per_page: 10, page: params[:page] || 1)
    
    if @artists.any?
      @music_library_artists = current_user.music_library_artists.where('music_library_artists.artist_id IN(?)', @artists.map(&:id)).index_by(&:artist_id)
    end
    
    params[:user_id] = @music_library_artist.user_id
    @pagination_params = { user_id: params[:user_id] }
    render layout: false
  end
  
  private
  
  def find_resource
    @music_library_artist = current_user.music_library_artists.where('music_library_artists.id = ?', params[:id]).first
  end
end