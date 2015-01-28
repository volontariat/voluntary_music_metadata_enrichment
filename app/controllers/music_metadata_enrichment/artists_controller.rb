class MusicMetadataEnrichment::ArtistsController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  authorize_resource class: 'MusicArtist', except: [:by_name]
  
  before_action :delete_user_id_which_is_not_from_current_user
  
  def index
    if request.xhr? 
      if request.original_url.match('/groups/') && params[:id]
        @group = MusicMetadataEnrichment::Group.find(params[:id])
        @artists = @group.artists
      elsif params[:user_id].present?
        @artists = User.find(params[:user_id]).music_artists
      end
      
      @artists = @artists.order('name ASC').paginate(per_page: 10, page: params[:page] || 1)
      
      if request.original_url.match('/groups/') && params[:id] && @artists.any?
        @group_artist_connections = @group.artist_connections.where('music_metadata_enrichment_group_artist_connections.artist_id IN(?)', @artists.map(&:id))
        @group_artist_connection_likes = current_user.likes_or_dislikes.for_targets('MusicMetadataEnrichment::GroupArtistConnection', @group_artist_connections.map(&:id)).index_by(&:target_id)
        @group_artist_connections = @group_artist_connections.index_by(&:artist_id)
      end
      
      render partial: 'music_metadata_enrichment/artists/collection', layout: false, locals: { title: I18n.t("music_metadata_enrichment_group_artist_connections.index.empty_collection"), paginate: true }
    end
  end
  
  def autocomplete
    render json: (
      MusicArtist.select('id, name').where("name LIKE ?", "#{params[:term]}%").order(:name).limit(10).map{|a| { id: a.id, value: a.name } }
    ), root: false
  end
  
  def new
    build_artist
  end
  
  def name_confirmation
    confirm_artist('new_artist')
  end
  
  def create
    params[:music_artist] ||= {}
    name_and_mbid = params[:music_artist].delete(:name_and_mbid)
    create_artist('new_artist', name_and_mbid)
  end
  
  def show
    @artist = MusicArtist.find(params[:id])
    get_variables_for_show
  end
  
  def by_name
     if params[:name].blank?
       flash[:alert] = I18n.t('music_artists.by_name.name_blank')
       redirect_to music_artists_path and return
     end
     
     @artists = MusicArtist.where("LOWER(name) = ?", params[:name].downcase.strip)
     @artist = @artists.first if params[:page].blank? && @artists.count == 1
    
    if @artist
      get_variables_for_show
      render :show
    else
      @artists = MusicArtist.name_like(params[:name]) if @artists.nil? || @artists.count == 0
      @artists = @artists.paginate(per_page: 10, page: params[:page] || 1)
    end
  end
  
  def resource
    @artist
  end
  
  private
  
  def delete_user_id_which_is_not_from_current_user
    params.delete(:user_id) if params[:user_id].present? && params[:user_id].to_i != current_user.id
  end
  
  def get_variables_for_show
    @releases = @artist.releases.order('released_at ASC')
  end
end