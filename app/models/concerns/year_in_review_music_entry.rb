module YearInReviewMusicEntry
  extend ActiveSupport::Concern
          
  included do
    belongs_to :year_in_review_music
    belongs_to :user
    
    scope :published, -> { where(state: 'published') }
    
    validates :year_in_review_music_id, presence: true
    
    attr_accessible :year_in_review_music_id, :user_id, :year
  end
end