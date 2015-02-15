class AddMatchesToYearInReviewsMusic < ActiveRecord::Migration
  def change
    add_column :year_in_review_music, :top_track_matches, :text
    add_column :year_in_review_music, :top_release_matches, :text
  end
end
