module YearInReviewMusicTrackBase
  extend ActiveSupport::Concern
          
  included do
    belongs_to :artist, class_name: 'MusicArtist'
    belongs_to :release, class_name: 'MusicRelease'
    belongs_to :track, class_name: 'MusicTrack'
      
    validates :track_id, presence: true, uniqueness: { scope: :year_in_review_music_id }
    validates :spotify_track_id, length: { is: 22 }, allow_blank: true
    
    attr_accessible :artist_id, :artist_name, :release_id, :release_name, :track_id, :spotify_track_id, :track_name
    
    before_save :set_cache_columns
    
    private
    
    def set_cache_columns
      unless !respond_to?(:user_id) || user_id.present?
        self.user_id = year_in_review_music.user_id
      end
      
      unless !respond_to?(:group_id) || group_id.present?
        self.group_id = year_in_review_music.group_id
      end
      
      self.year = year_in_review_music.year unless year.present?
      self.artist_id = track.artist_id unless artist_id.present?
      self.artist_name = track.artist_name unless artist_name.present? && !track_id_changed?
      self.release_id = track.release_id unless release_id.present? && !track_id_changed?
      self.release_name = track.release_name unless release_name.present? && !track_id_changed?
      self.track_name = track.name unless track_name.present? && !track_id_changed?
      self.spotify_track_id = track.spotify_track_id unless spotify_track_id.present?
      self.released_at = track.released_at unless released_at.present?
    end
  end
end