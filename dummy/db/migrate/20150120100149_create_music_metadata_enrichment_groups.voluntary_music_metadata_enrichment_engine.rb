# This migration comes from voluntary_music_metadata_enrichment_engine (originally 20150120091801)
class CreateMusicMetadataEnrichmentGroups < ActiveRecord::Migration
  def change
    create_table :music_metadata_enrichment_groups do |t|
      t.string :name
      t.integer :user_id
      t.string :current_user_name
      t.integer :current_members_page
      t.integer :synced
      t.timestamps
    end
  end
end