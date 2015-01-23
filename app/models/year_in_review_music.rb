class YearInReviewMusic < ActiveRecord::Base
  self.table_name = 'year_in_review_music'
  
  belongs_to :user
  
  has_many :year_in_review_music_releases, dependent: :destroy
  has_many :year_in_review_music_tracks, dependent: :destroy
  
  validates :user_id, presence: true
  validates :year, presence: true, numericality: { only_integer: true }, uniqueness: { scope: :user_id }
  
  attr_accessible :user_id, :year
end