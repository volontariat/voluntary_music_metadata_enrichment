class AddProductMusicMetadataEnrichment < ActiveRecord::Migration
  def up
    if product = Product.where(name: 'Music Metadata Enrichment').first
    else
      Product.create(name: 'Music Metadata Enrichment', text: 'Dummy') 
    end
    
    create_table :music_genres do |t|
      t.string :ancestry
      t.string :name
      t.timestamps
    end
    
    add_index :music_genres, :ancestry
    
    create_table :music_artists do |t|
      t.string :mbid
      t.integer :genre_id
      t.string :name
      t.integer :listeners
      t.integer :plays
      t.datetime :founded_at
      t.datetime :dissolved_at
      t.string :state
      t.timestamps
    end
    
    add_index :music_artists, :genre_id
    add_index :music_artists, :name, unique: true
    
    create_table :music_releases do |t|
      t.string :mbid
      t.integer :genre_id
      t.integer :artist_id
      t.string :artist_name
      t.string :name
      t.integer :discs_count
      t.integer :tracks_count
      t.string :future_release_date
      t.datetime :released_at
      t.integer :listeners
      t.integer :plays
      t.integer :user_id
      t.string :state
      t.timestamps
    end
    
    add_index :music_releases, :artist_id
    add_index :music_releases, [:artist_id, :name], unique: true
    
    create_table :music_discs do |t|
      t.string :mbid
      t.integer :genre_id
      t.integer :artist_id
      t.string :artist_name
      t.integer :release_id
      t.string :release_name
      t.integer :nr
      t.string :name
      t.integer :tracks_count
      t.integer :listeners
      t.integer :plays
      t.string :state
      t.timestamps
    end
    
    add_index :music_discs, :release_id
    add_index :music_discs, [:release_id, :name], unique: true
    
    create_table :music_tracks do |t|
      t.string :mbid
      t.integer :genre_id
      t.integer :artist_id
      t.string :artist_name
      t.integer :release_id
      t.string :release_name
      t.integer :disc_id
      t.string :disc_name
      t.integer :master_track_id
      t.integer :nr
      t.string :name
      t.integer :duration
      t.integer :listeners
      t.integer :plays
      t.string :state
      t.timestamps
    end
    
    add_index :music_tracks, :disc_id
    add_index :music_tracks, [:disc_id, :name], unique: true
    
    create_table :music_videos do |t|
      t.string :type
      t.integer :genre_id
      t.integer :artist_id
      t.string :artist_name
      t.integer :track_id
      t.string :track_name
      t.string :url
      t.string :location
      t.datetime :recorded_at
      t.integer :user_id
      t.string :state
      t.timestamps
    end
    
    add_index :music_videos, [:type, :track_id], unique: true
    add_index :music_videos, :url, unique: true
    add_index :music_videos, :track_id
  end
  
  def down
    drop_table :music_genres
    drop_table :music_artists
    drop_table :music_releases
    drop_table :music_discs
    drop_table :music_tracks
    drop_table :music_videos
    drop_table :music_video_sources
  end
end
