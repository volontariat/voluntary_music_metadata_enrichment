# -*- encoding : utf-8 -*-
class MusicVideo < ActiveRecord::Base
  include Likeable
  
  STATUSES = %w(Official Unofficial Live)
  
  belongs_to :track, class_name: 'MusicTrack'
  belongs_to :user
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  
  scope :by_artist_and_name, ->(artist_name, track_name) do
    where(
      "LOWER(artist_name) = :artist_name AND LOWER(track_name) = :track_name", 
      artist_name: artist_name.downcase.strip, track_name: track_name.downcase.strip
    )
  end
  
  scope :artist_and_name_like, ->(artist_name, track_name) do
    table = MusicVideo.arel_table
    where(table[:artist_name].matches("%#{artist_name}%").and(table[:track_name].matches("%#{track_name}%")))
  end  
  
  validates :track_id, presence: true
  validates :url, presence: true, uniqueness: { case_sensitive: false }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :one_live_or_official_video_per_track
  validate :url_format
  
  attr_accessible :status, :track_id, :track_name, :url, :location, :recorded_at
  
  before_create :set_artist
  before_create :set_track_name
  
  auto_html_for :url do
    youtube(width: 515, height: 300)
    dailymotion(width: 515, height: 300)
    vimeo(width: 515, height: 300)
    google_video(width: 515, height: 300)
    link :target => "_blank", :rel => "nofollow"
  end
  
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
  
  def to_json
    { 
      id: id, status: status, artist_id: artist_id, artist_name: artist_name, 
      track_id: track_id, track_name: track_name, url: url
    } 
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