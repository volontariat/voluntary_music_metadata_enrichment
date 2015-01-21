# This migration comes from voluntary_music_metadata_enrichment_engine (originally 20150120224142)
class CreateMusicTrackRankingsAndMatches < ActiveRecord::Migration
  def change
    create_table :user_music_track_rankings do |t|
      t.integer :user_id
      t.integer :track_id
      t.integer :won_matches_count, default: 0
      t.timestamps
    end
    
    add_index :user_music_track_rankings, :user_id
    
    create_table :user_music_track_matches do |t|
      t.integer :user_id
      t.integer :left_id
      t.integer :right_id
      t.integer :winner_id
      t.integer :loser_id
      t.string :state
      t.timestamps
    end
    
    add_index :user_music_track_matches, :user_id
    add_index :user_music_track_matches, :winner_id
    add_index :user_music_track_matches, :state
  end
end
