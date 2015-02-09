module YearInReviewMusicReleaseBase
  extend ActiveSupport::Concern
          
  included do
    belongs_to :artist, class_name: 'MusicArtist'
    belongs_to :release, class_name: 'MusicRelease'
    
    validates :release_id, presence: true, uniqueness: { scope: :year_in_review_music_id }
    
    attr_accessible :year_in_review_music_id, :user_id, :year, :artist_id, :artist_name, :release_id, :release_name
    
    before_create :set_cache_columns
    
    private
    
    def set_cache_columns
      self.user_id = year_in_review_music.user_id unless user_id.present?
      self.year = year_in_review_music.year unless year.present?
      self.artist_id = release.artist_id unless artist_id.present?
      self.artist_id = release.artist_id unless artist_id.present?
      self.artist_name = release.artist_name unless artist_name.present?
      self.release_name = release.name unless release_name.present?
      self.released_at = release.released_at unless released_at.present?
    end
  end
end