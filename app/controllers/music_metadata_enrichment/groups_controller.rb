class MusicMetadataEnrichment::GroupsController < ::MusicMetadataEnrichment::ApplicationController
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
      redirect_to music_group_path(@group)
    else
      render :new
    end
  end
  
  def show
    @group = MusicMetadataEnrichment::Group.find(params[:id])
    @year = Time.now.strftime('%Y')
    @releases = @group.releases.released_in_year(@year).order('released_at DESC')
  end
  
  def resource
    @group
  end
  
  private
  
  def build_group
    @group = MusicMetadataEnrichment::Group.new(params[:music_metadata_enrichment_group])
  end
end