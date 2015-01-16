# -*- encoding : utf-8 -*-
class MusicVideo < ActiveRecord::Base
  STATUSES = %w(Official Unofficial Live)
  
  belongs_to :track, class_name: 'MusicTrack'
  belongs_to :user
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  
  validates :track_id, presence: true
  validates :url, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :one_live_or_official_video_per_track
  validate :url_format
  
  attr_accessible :status, :track_id, :track_name, :url, :location, :recorded_at
  
  before_save :set_artist
  before_save :set_track_name
  
  def self.order_by_status
    if Rails.env.production?
      order_by = ["case"]
      
      STATUSES.each_with_index.map do |status, index|
        order_by << "WHEN status='#{status}' THEN #{index}"
      end
      
      order_by << "end"
      order(order_by.join(" "))
    else
      order("FIELD(status, '#{STATUSES.join("','")}')")
    end
  end
  
  def name
    "#{track.artist_name } – #{track_name} (#{status})"
  end
  
  private
  
  def url_format
    unless url =~ URI::regexp
      errors[:url] << I18n.t('activerecord.errors.models.music_video.attributes.url.wrong_format')
    end
  end
  
  def one_live_or_official_video_per_track
    return if status == 'Unofficial'
    
    if track.videos.where(status: status).any?
      errors[:status] << I18n.t('activerecord.errors.models.music_video.attributes.status.one_live_or_official_video_per_track')
    end
  end
  
  def set_artist
    self.artist_id = track.artist_id
    self.artist_name = track.artist_name
  end
  
  def set_track_name
    self.track_name = track.name
  end
end