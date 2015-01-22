class MusicMetadataEnrichment::GroupArtistConnectionsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  authorize_resource class: 'MusicMetadataEnrichment::GroupArtistConnection'
  
  def import
    @group = MusicMetadataEnrichment::Group.find(params[:group_id])
    
    if params[:music_metadata_enrichment_group].present?
      @group.artist_connections_text = params[:music_metadata_enrichment_group][:artist_connections_text]
      artist_names_without_mbid = @group.import_artist_connections
      
      if artist_names_without_mbid.any?
        flash[:notice] = I18n.t(
          'music_metadata_enrichment_group_artist_connections.import.success_with_missing_artist_mbids', artist_names: artist_names_without_mbid.join(', ')
        )
      else
        flash[:notice] = I18n.t('music_metadata_enrichment_group_artist_connections.import.success')
      end
      
      redirect_to music_group_path(@group.id)
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
      redirect_to music_group_path(params[:group_artist_connection][:group_id])
    else
      @group_artist_connection = MusicMetadataEnrichment::GroupArtistConnection.new(
        group_id: params[:group_artist_connection][:group_id], artist_id: params[:group_artist_connection][:artist_id]
      )
      
      if @group_artist_connection.save
        flash[:notice] = I18n.t('music_metadata_enrichment_group_artist_connections.creation.success')
      else
        flash[:alert] = @group_artist_connection.errors.full_messages.join('. ')
      end
      
      redirect_to music_group_path(@group_artist_connection.group_id)
    end
  end
  
  def resource
    @group_artist_connection
  end
end