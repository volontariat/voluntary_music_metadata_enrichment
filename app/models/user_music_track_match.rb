class UserMusicTrackMatch < ActiveRecord::Base
  attr_accessible :user_id, :left_id, :right_id, :winner_id, :loser_id
  
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_track, ->(track_id) { where('left_id = ? OR right_id = ?', track_id) }
  
  scope :for_tracks, ->(track_id1, track_id2) do
    where('(left_id = :track_id1 OR right_id = :track_id1) AND (left_id = :track_id2 OR right_id = :track_id2)', track_id1: track_id1, track_id2: track_id2)
  end
  
  scope :unrated, -> { where(state: 'unrated') }
  scope :rated, -> { where(state: 'rated') }
  
  scope :winner_is, ->(track_id) { where(winner_id: track_id) }
  scope :winner_is_not, ->(track_id) { where('winner_id <> ?', track_id) }
  
  validates :user_id, presence: true
  validates :left_id, presence: true
  validates :right_id, presence: true
  validates :winner_id, presence: true, if: 'state == "rated"'
  validates :loser_id, presence: true, if: 'state == "rated"'
  validate :uniq_match
  
  after_save :let_winner_win_matches_of_tracks_which_lose_against_the_loser
  
  state_machine :state, initial: :unrated do
    event :rate do transition :unrated => :rated; end
  end
  
  private
  
  def let_winner_win_matches_of_tracks_which_lose_against_the_loser
    return unless winner_id.present? && winner_id_changed?
    
    UserMusicTrackMatch.for_user(user_id).winner_is(loser_id).find_each do |won_match_of_loser|
      another_match = UserMusicTrackMatch.for_user(user_id).for_tracks(winner_id, won_match_of_loser.loser_id).winner_is_not(winner_id).first
      
      next unless another_match
      
      another_match.winner_id = match.winner_id
      another_match.loser_id = another_match.left_id == winner_id ? another_match.right_id : another_match.left_id
      
      another_match.unrated? ? another_match.rate! : another_match.save
    end
    
    UserMusicTrackRanking.where(
      user_id: match.user_id, track_id: match.winner_id
    ).first.update_attribute(:won_matches_count, UserMusicTrackMatch.for_user(match.user_id).winner_is(match.winner_id).count)
  end
  
  def uniq_match
    if UserMusicTrackMatch.where(user_id: user_id).for_tracks(left_id, right_id).any?
      errors[:base] << I18n.t('activerecord.errors.models.user_music_track_match.base.match_not_uniq')
    end
  end
end