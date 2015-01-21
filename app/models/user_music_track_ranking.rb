class UserMusicTrackRanking < ActiveRecord::Base
  belongs_to :user
  belongs_to :track, class_name: 'MusicTrack'
  
  validates :user_id, presence: true
  validates :track_id, presence: true, uniqueness: { scope: :user_id }
  
  attr_accessible :user_id, :track_id, :won_matches_count
end