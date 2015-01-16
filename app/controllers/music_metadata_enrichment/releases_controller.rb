# -*- encoding : utf-8 -*-
class MusicMetadataEnrichment::ReleasesController < ApplicationController
  include ::MusicMetadataEnrichment::BaseController
  include Applicat::Mvc::Controller::Resource
  include ::MusicMetadataEnrichment::ArtistConfirmation
  
  def index
  end
  
  def new
    build_artist
  end
  
  def artist_confirmation
    confirm_artist('new_release')
  end
  
  def select_artist
    params[:music_artist] ||= {}
    name_and_mbid = params[:music_artist].delete(:name_and_mbid)
    artist = MusicArtist.where(mbid: name_and_mbid.split(';').last).first
    
    if artist && artist.active?
      redirect_to name_music_metadata_enrichment_releases_path(music_release: { artist_id: artist.id })
    elsif artist
      flash[:notice] = I18n.t('music_releases.select_artist.wait_until_artist_metadata_import_completed')
      redirect_to music_metadata_enrichment_releases_path 
    else
      create_artist('new_release', name_and_mbid)
    end
  end
  
  def name
    build_release
  end
  
  def name_confirmation
    build_release
    @release_groups = @release.groups

    if @release_groups.none? && @release.groups_without_limitation.none?
      flash[:notice] = I18n.t('music_releases.name_confirmation.release_not_found')
      redirect_to announce_music_metadata_enrichment_releases_path(music_release: { artist_id: params[:music_release][:artist_id], name: params[:music_release][:name] })
    end
  end
  
  def create
    params[:music_release] ||= {}
    name_and_mbid = params[:music_release].delete(:name_and_mbid)
    artist = MusicArtist.find(params[:music_release][:artist_id])
    release = MusicRelease.where(artist_id: artist.id, name: name_and_mbid.split(';').first).first
    
    if release
      flash[:alert] = I18n.t('music_releases.create.release_already_imported')
      redirect_to music_metadata_enrichment_releases_path 
    else
      release = MusicRelease.create(
        artist_id: params[:music_release][:artist_id], artist_name: artist.name, 
        name: name_and_mbid.split(';').first
      )
      
      if release.valid?
        flash[:notice] = I18n.t('music_releases.create.scheduled_release_for_import')
        redirect_to music_metadata_enrichment_releases_path
      else
        flash[:alert] = release.errors.full_messages.join('. ')
        redirect_to music_metadata_enrichment_releases_path
      end
    end
  end
  
  def announce
    build_release
    
    if MusicRelease.where(artist_id: @release.artist_id, name: @release.name).first
      flash[:alert] = I18n.t('music_releases.create.release_already_imported')
      redirect_to music_metadata_enrichment_releases_path 
    elsif @release.groups.any?
      flash[:notice] = I18n.t('music_releases.announce.please_select_existing_release')
      redirect_to name_confirmation_music_metadata_enrichment_releases_path(music_release: { artist_id: params[:music_release][:artist_id], name: params[:music_release][:name] })
    end
  end
  
  def create_announcement
    build_release
    
    if MusicRelease.where(artist_id: @release.artist_id, name: @release.name).first
      flash[:alert] = I18n.t('music_releases.create.release_already_imported')
      redirect_to music_metadata_enrichment_releases_path 
    elsif @release.groups.any?
      flash[:notice] = I18n.t('music_releases.announce.please_select_existing_release')
      redirect_to name_confirmation_music_metadata_enrichment_releases_path(music_release: { artist_id: params[:music_release][:artist_id], name: params[:music_release][:name] })
    elsif @release.future_release_date.blank? || !@release.valid?
      if @release.future_release_date.blank?
        @release.errors[:future_release_date] << I18n.t('errors.messages.blank')
      end
      
      render :announce
    else
      artist = MusicArtist.find(params[:music_release][:artist_id])
      @release.save!
      flash[:notice] = I18n.t('music_releases.create_announcement.success')
      redirect_to music_metadata_enrichment_releases_path
    end
  end
  
  def show
    @release = MusicRelease.find(params[:id])
    @tracks = @release.tracks.order('nr ASC')
  end
  
  def resource
    @release
  end
  
  private
  
  def build_release
    params[:music_release] ||= {}
    @release = MusicRelease.new
    @release.name = params[:music_release][:name]
    @release.mbid = params[:music_release][:mbid] unless ['announce', 'create_announcement'].include? action_name
    @release.artist_id = params[:music_release][:artist_id]
    @release.future_release_date = params[:music_release][:future_release_date] if ['announce', 'create_announcement'].include? action_name
  end
end