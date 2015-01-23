class YearInReviewMusicTrack < ActiveRecord::Base
  include YearInReviewMusicEntry
  
  belongs_to :artist, class_name: 'MusicArtist'
  belongs_to :release, class_name: 'MusicRelease'
  belongs_to :track, class_name: 'MusicTrack'
    
  validates :track_id, presence: true, uniqueness: { scope: :year_in_review_music_id }
  validates :spotify_track_id, length: { is: 22 }, allow_blank: true
  
  attr_accessible :year_in_review_music_id, :user_id, :year, :artist_id, :artist_name, :release_id, :release_name, :track_id, :spotify_track_id, :track_name
  
  before_create :set_cache_columns
  
  private
  
  def set_cache_columns
    self.user_id = year_in_review_music.user_id unless user_id.present?
    self.year = year_in_review_music.year unless year.present?
    self.artist_id = track.artist_id unless artist_id.present?
    self.artist_name = track.artist_name unless artist_name.present?
    self.release_id = track.release_id unless release_id.present?
    self.release_name = track.release_name unless release_name.present?
    self.track_name = track.name unless track_name.present?
    self.spotify_track_id = track.spotify_track_id unless spotify_track_id.present?
  end
end