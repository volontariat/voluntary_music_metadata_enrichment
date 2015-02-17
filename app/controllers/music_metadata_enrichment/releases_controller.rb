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
  end
  
  def artist_confirmation
    confirm_artist('new_release')
  end
  
  def select_artist
    artist_selection('new_release')
  end
  
  def name
    build_release
  end
  
  def name_confirmation
    build_release
    @release_groups = @release.groups(true)
    
    if @release_groups.none?
      flash[:notice] = I18n.t('music_releases.name_confirmation.release_not_found')
      redirect_to announce_music_releases_path(
        (params[:group_id].present? ? {group_id: params[:group_id]} : {}).merge(
          music_release: { artist_id: params[:music_release][:artist_id], name: params[:music_release][:name] }
        )
      )
    end
  end
  
  def create
    params[:music_release] ||= {}
    name_and_mbid = params[:music_release].delete(:name_and_mbid).split(';')
    artist = MusicArtist.find(params[:music_release][:artist_id])
    musicbrainz_release_group = MusicBrainz::ReleaseGroup.find(name_and_mbid.last)
    is_lp = musicbrainz_release_group.type == 'Album'
    release = MusicRelease.where(artist_id: artist.id, name: name_and_mbid.first, is_lp: is_lp).first
    
    if release
      flash[:alert] = I18n.t('music_releases.create.release_already_imported')
    else
      release = MusicRelease.create(
        artist_id: params[:music_release][:artist_id], artist_name: artist.name, name: name_and_mbid.first, is_lp: is_lp
      )
      
      if release.valid?
        flash[:notice] = I18n.t('music_releases.create.scheduled_release_for_import')
      else
        flash[:alert] = release.errors.full_messages.join('. ')
      end
    end
    
    if params[:group_id].present?
      redirect_to music_group_path(params[:group_id])
    else
      redirect_to music_path
    end
  end
  
  def announce
    build_release
  end
  
  def create_announcement
    build_release

    if @release.future_release_date.blank? || !@release.valid?
      if @release.future_release_date.blank?
        @release.errors[:future_release_date] << I18n.t('errors.messages.blank')
      end
      
      render :announce
    else
      @release.save!
      flash[:notice] = I18n.t('music_releases.create_announcement.success')
      
      if params[:group_id].present?
        redirect_to music_group_path(params[:group_id])
      else
        redirect_to music_path 
      end
    end
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
     
    @releases = MusicRelease.by_artist_and_name(params[:artist_name], params[:name])
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
    @year_in_review_music_releases = @release.year_in_review_tops.where('year_in_review_music_releases.position < 11').group('position').count
  end
end