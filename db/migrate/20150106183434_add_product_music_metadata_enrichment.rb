class AddProductMusicMetadataEnrichment < ActiveRecord::Migration
  def up
    if Product.where(name: 'Music Metadata Enrichment').first
    else
      Product.create(name: 'Music Metadata Enrichment', text: 'Dummy') 
    end
    
    create_table :music_artists do |t|
      t.string :mbid
      t.string :name
      t.integer :listeners
      t.integer :plays
      t.datetime :founded_at
      t.datetime :dissolved_at
      t.string :state
      t.timestamps
    end

    add_index :music_artists, :mbid, unique: true
    
    create_table :music_releases do |t|
      t.string :mbid
      t.integer :artist_id
      t.string :artist_name
      t.string :name
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
    add_index :music_releases, :mbid, unique: true
    
    create_table :music_tracks do |t|
      t.string :mbid
      t.integer :artist_id
      t.string :artist_name
      t.integer :release_id
      t.string :release_name
      t.integer :master_track_id
      t.integer :nr
      t.string :name
      t.integer :duration
      t.integer :listeners
      t.integer :plays
      t.string :state
      t.timestamps
    end
    
    add_index :music_tracks, :release_id
    add_index :music_tracks, [:release_id, :name], unique: true
    
    create_table :music_videos do |t|
      t.string :type
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
    
    add_column :users, :lastfm_user_name, :string
    add_column :users, :music_library_imported, :boolean, default: false
  end
  
  def down
    drop_table :music_artists
    drop_table :music_releases
    drop_table :music_tracks
    drop_table :music_videos
    
    remove_column :users, :lastfm_user_name
    remove_column :users, :music_library_imported
  end
end
