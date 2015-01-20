class MusicMetadataEnrichment::GroupsController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  authorize_resource

  def index
  end
  
  def new
    build_group
  end
  
  def create
    build_group
    
    if @group.save
      flash[:notice] = I18n.t('music_metadata_enrichment_groups.create.successful')
      redirect_to music_metadata_enrichment_group_path(@group)
    else
      render :new
    end
  end
  
  def show
    @group = MusicMetadataEnrichment::Group.find(params[:id])
  end
  
  def resource
    @group
  end
  
  private
  
  def build_group
    @group = MusicMetadataEnrichment::Group.new(params[:music_metadata_enrichment_group])
  end
end