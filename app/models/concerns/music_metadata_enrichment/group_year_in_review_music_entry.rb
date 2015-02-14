module MusicMetadataEnrichment
  module GroupYearInReviewMusicEntry
    extend ActiveSupport::Concern
            
    included do
      belongs_to :year_in_review_music, class_name: 'MusicMetadataEnrichment::GroupYearInReviewMusic'
      belongs_to :group, class_name: 'MusicMetadataEnrichment::Group'
      
      validates :year_in_review_music_id, presence: true
      
      attr_accessible :year_in_review_music_id, :group_id, :year, :position, :score
    end
  end
end