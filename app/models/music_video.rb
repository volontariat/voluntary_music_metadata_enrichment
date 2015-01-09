class MusicVideo < ActiveRecord::Base
  belongs_to :track, class_name: 'MusicTrack'
  belongs_to :user
  
  # cached associations
  belongs_to :artist, class_name: 'MusicArtist'
  
  validates :track_id, presence: true
  validates :url, uniqueness: true
  validates :type, uniqueness: { scope: :track_id }
  
  attr_accessible :type, :artist_id, :artist_name, :track_id, :track_name, :url, :location, :recorded_at
end