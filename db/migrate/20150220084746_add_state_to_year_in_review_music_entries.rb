class AddStateToYearInReviewMusicEntries < ActiveRecord::Migration
  def change
    add_column :year_in_review_music, :state, :string, default: 'draft'
    add_column :year_in_review_music_releases, :state, :string, default: 'draft'
    add_column :year_in_review_music_tracks, :state, :string, default: 'draft'
  end
end
