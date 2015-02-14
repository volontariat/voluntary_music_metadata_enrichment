module YearInReviewMusicReleaseBase
  extend ActiveSupport::Concern
          
  included do
    belongs_to :artist, class_name: 'MusicArtist'
    belongs_to :release, class_name: 'MusicRelease'
    
    validates :release_id, presence: true, uniqueness: { scope: :year_in_review_music_id }
    
    attr_accessible :artist_id, :artist_name, :release_id, :release_name
    
    before_create :set_cache_columns
    
    private
    
    def set_cache_columns
      unless !respond_to?(:user_id) || user_id.present?
        self.user_id = year_in_review_music.user_id
      end
      
      unless !respond_to?(:group_id) || group_id.present?
        self.group_id = year_in_review_music.group_id
      end
      
      self.year = year_in_review_music.year unless year.present?
      self.artist_id = release.artist_id unless artist_id.present?
      self.artist_id = release.artist_id unless artist_id.present?
      self.artist_name = release.artist_name unless artist_name.present?
      self.release_name = release.name unless release_name.present?
      self.released_at = release.released_at unless released_at.present?
    end
  end
end