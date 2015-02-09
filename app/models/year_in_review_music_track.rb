class YearInReviewMusicTrack < ActiveRecord::Base
  include YearInReviewMusicEntry
  include YearInReviewMusicTrackBase
  
  acts_as_list scope: :year_in_review_music_id
end