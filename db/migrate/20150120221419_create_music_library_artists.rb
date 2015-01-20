class CreateMusicLibraryArtists < ActiveRecord::Migration
  def change
    create_table :music_library_artists do |t|
      t.integer :user_id
      t.integer :artist_id
      t.integer :plays
      t.timestamps
    end
  end
end
