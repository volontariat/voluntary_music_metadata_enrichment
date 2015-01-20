class MusicMetadataEnrichment::GroupArtistConnectionsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  authorize_resource class: 'MusicMetadataEnrichment::GroupArtistConnection'
  
  def index
    if request.xhr? 
      group = MusicMetadataEnrichment::Group.find(params[:group_id])
      @artists = group.artists.order('name ASC').paginate(per_page: 10, page: params[:page] || 1)
      render partial: 'music_metadata_enrichment/artists/collection', layout: false, locals: { paginate: true }
    end
  end
  
  def new
    build_artist
  end
  
  def name_confirmation
    confirm_artist('new_group_artist_connection')
  end
  
  def select_artist
    artist_selection('new_group_artist_connection')
  end
  
  def creation
    if MusicMetadataEnrichment::GroupArtistConnection.where(
      group_id: params[:group_artist_connection][:group_id], artist_id: params[:group_artist_connection][:artist_id]
    ).any?
      flash[:alert] = I18n.t('music_metadata_enrichment_group_artist_connections.creation.already_created')
      redirect_to music_metadata_enrichment_group_path(params[:group_artist_connection][:group_id])
    else
      @group_artist_connection = MusicMetadataEnrichment::GroupArtistConnection.new(
        group_id: params[:group_artist_connection][:group_id], artist_id: params[:group_artist_connection][:artist_id]
      )
      
      if @group_artist_connection.save
        flash[:notice] = I18n.t('music_metadata_enrichment_group_artist_connections.creation.success')
      else
        flash[:alert] = @group_artist_connection.errors.full_messages.join('. ')
      end
      
      redirect_to music_metadata_enrichment_group_path(@group_artist_connection.group_id)
    end
  end
  
  def resource
    @group_artist_connection
  end
end