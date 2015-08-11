class AddClassicAndJazzTagsToMusicArtists < ActiveRecord::Migration
  def change
    add_column :music_artists, :is_classic, :boolean, null: false, default: false
    add_column :music_artists, :is_jazz, :boolean, null: false, default: false
  end
end
