class MusicMetadataEnrichment::GroupMembershipsController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource

  load_and_authorize_resource instance_name: 'membership'
  
  def create
    @group = MusicMetadataEnrichment::Group.find(params[:group_id])
    @membership = @group.memberships.create(user_id: current_user.id)
    
    render layout: false
  end
  
  def destroy
    @group = @membership.group
    @membership.destroy
    
    render layout: false
  end
end
