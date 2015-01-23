module YearInReviewMusicEntry
  extend ActiveSupport::Concern
          
  included do
    belongs_to :year_in_review_music
    belongs_to :user
    
    validates :year_in_review_music_id, presence: true
    
    acts_as_list scope: :year_in_review_music_id
  end
end