class YearInReviewMusicRelease < ActiveRecord::Base
  include YearInReviewMusicEntry
  include YearInReviewMusicReleaseBase
  
  acts_as_list scope: :year_in_review_music_id
end