class MusicMetadataEnrichment::GroupReleaseConnectionsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  
  authorize_resource class: 'MusicMetadataEnrichment::GroupArtistConnection'
  
  def index
    if request.xhr? 
      @group = MusicMetadataEnrichment::Group.find(params[:id])
      @year = params[:year]
      @releases = @group.releases.released_in_year(params[:year]).order('released_at DESC')
      render partial: 'music_metadata_enrichment/releases/collection', locals: { paginate: false, with_artist: true }, layout: false
    end
  end
end