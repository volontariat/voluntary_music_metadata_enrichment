class AddIsLpToMusicReleases < ActiveRecord::Migration
  def change
    add_column :music_releases, :is_lp, :boolean, null: false, default: false
  end
end
