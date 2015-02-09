class AddIsAmbiguousToMusicArtists < ActiveRecord::Migration
  def change
    add_column :music_artists, :is_ambiguous, :boolean, default: nil
  end
end
