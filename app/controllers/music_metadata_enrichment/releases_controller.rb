# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::ReleasesController < ::MusicMetadataEnrichment::ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  authorize_resource class: 'MusicRelease', except: [:by_name, :export]
  
  def index
    if request.xhr? 
      @year = params[:year]
      
      if request.original_url.match('/groups/') && params[:id]
        @group = MusicMetadataEnrichment::Group.find(params[:id])
        @releases = @group.releases
      elsif params[:user_id].present?
        @user = User.find(params[:user_id])
        @releases = @user.music_releases
      end
      
      @releases = @releases.released_in_year(params[:year]).order('released_at DESC').paginate(per_page: 25, page: params[:page] || 1)
      
      render partial: 'music_metadata_enrichment/releases/collection', locals: { paginate: true, with_artist: true }, layout: false
    end
  end
  
  def autocomplete
    artist = MusicArtist.find(params[:artist_id])
    render json: (
      artist.releases.select('id, is_lp, name').where("LOWER(name) LIKE ?", "#{params[:term].to_s.strip.downcase}%").order(:name).limit(10).map{|r| { id: r.id, value: "#{r.name} (#{r.is_lp ? 'LP' : 'EP'})" } }
    ), root: false
  end
  
  def new
    if params[:artist_id].present?
      redirect_to name_music_releases_path(music_release: { artist_id: params[:artist_id]})
    else
      build_artist
    end
    
    set_template_name_for_xhr_or_render
  end
  
  def artist_confirmation
    confirm_artist('new_release')
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def select_artist
    artist_selection('new_release')
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def name
    build_release
    
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def name_confirmation
    build_release
    @release_groups = @release.groups(true)
    
    if @release_groups.none?
      flash[:notice] = I18n.t('music_releases.name_confirmation.release_not_found')
      @path = announce_music_releases_path(
        (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(
          music_release: { artist_id: params[:music_release][:artist_id], name: params[:music_release][:name] }
        )
      )
    end
    
    set_template_name_for_xhr_or_render
    
    redirect_to @path unless @path.blank? || request.xhr?
    render_modal_javascript_response if request.xhr?
  end
  
  def create
    params[:music_release] ||= {}
    name_and_mbid = params[:music_release].delete(:name_and_mbid).split(';')
    artist = MusicArtist.find(params[:music_release][:artist_id])
    musicbrainz_release_group = MusicBrainz::ReleaseGroup.find(name_and_mbid.last)
    is_lp = musicbrainz_release_group.type == 'Album'
    @release = MusicRelease.where(artist_id: artist.id, name: name_and_mbid.first, is_lp: is_lp).first
    
    if @release
      flash[:alert] = I18n.t('music_releases.create.release_already_imported')
    else
      @release = MusicRelease.create(
        artist_id: params[:music_release][:artist_id], artist_name: artist.name, name: name_and_mbid.first, is_lp: is_lp
      )
      
      if @release.persisted?
        flash[:notice] = I18n.t('music_releases.create.scheduled_release_for_import')
      else
        flash[:alert] = release.errors.full_messages.join('. ')
      end
    end
    
    add_to_year_in_review_music_top_releases if @release.persisted? && params[:year_in_review_music_id].present?
    @path = (params[:group_id].present? ? music_group_path(params[:group_id]) : music_path) unless params[:year_in_review_music_id].present?
    
    redirect_to @path unless @path.blank? || request.xhr?
    render_modal_javascript_response if request.xhr?
  end
  
  def announce
    build_release
    set_template_name_for_xhr_or_render
    
    render_modal_javascript_response if request.xhr?
  end
  
  def create_announcement
    build_release

    if @release.future_release_date.blank? || !@release.valid?
      if @release.future_release_date.blank?
        @release.errors[:future_release_date] << I18n.t('errors.messages.blank')
      end
      
      @template = :announce
    else
      @release.save!
      flash[:notice] = I18n.t('music_releases.create_announcement.success')
      
      @path = params[:group_id].present? ? music_group_path(params[:group_id]) : music_path 
    end
        
    add_to_year_in_review_music_top_releases if @release.persisted? && params[:year_in_review_music_id].present?
    
    render @template if @template.present? && !request.xhr?
    redirect_to @path unless @path.blank? || request.xhr?
    render_modal_javascript_response if request.xhr?
  end
  
  def show
    @release = MusicRelease.find(params[:id])
    get_variables_for_show
  end
  
  def by_name
    if params[:artist_name].blank? || params[:name].blank?
       flash[:alert] = I18n.t('music_releases.by_name.artist_name_or_name_blank')
       redirect_to music_releases_path(artist_name: params[:artist_name], name: params[:name]) and return
     end
     
    @releases = MusicRelease.by_artist_and_name([params[:artist_name], params[:name]])
    @release = @releases.first if params[:page].blank? && @releases.count == 1
    
    if @release
      get_variables_for_show
      render :show
    else
      @releases = MusicRelease.artist_and_name_like(params[:artist_name], params[:name]) if @releases.nil? || @releases.count == 0
      @releases = @releases.paginate(per_page: 10, page: params[:page] || 1)
    end
  end
  
  def export
    @group = MusicMetadataEnrichment::Group.find(params[:id])
    @current_releases = @group.releases.released_in_year(Time.now.strftime('%Y')).order('released_at ASC')
    @future_releases = @group.releases.released_in_year(Time.now.strftime('%Y').to_i + 1).order('released_at ASC')
    
    render layout: false
  end
  
  def resource
    @release
  end
  
  private
  
  def build_release
    params[:music_release] ||= {}
    @release = MusicRelease.new
    @release.is_lp = params[:music_release][:is_lp]
    @release.name = params[:music_release][:name]
    @release.mbid = params[:music_release][:mbid] unless ['announce', 'create_announcement'].include? action_name
    @release.artist_id = params[:music_release][:artist_id]
    @release.future_release_date = params[:music_release][:future_release_date] if ['announce', 'create_announcement'].include? action_name
    @release.user_id = current_user.id
  end
  
  def get_variables_for_show
    if @release.name == '[Bonus Tracks]'
      @tracks = @release.tracks.order('released_at ASC')
    else
      @tracks = @release.tracks.order('nr ASC')
    end
    
    @tracks = @tracks.paginate(per_page: 50, page: params[:tracks_page] || 1)
    @year_in_review_music_releases = @release.year_in_review_tops.published.group('position').count
  end
  
  def add_to_year_in_review_music_top_releases
    year_in_review_music = current_user.years_in_review_music.where(id: params[:year_in_review_music_id]).first
    @path = create_user_music_year_in_review_top_release_path(year_in_review_music.user_id, year_in_review_music.year)
    @data = { year_in_review_music_release: { release_id: @release.id } }
    @method = :post
  end
end