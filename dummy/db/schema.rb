# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150220084859) do

  create_table "areas", force: :cascade do |t|
    t.string   "ancestry",       limit: 255
    t.integer  "ancestry_depth", limit: 4,   default: 0
    t.integer  "position",       limit: 4
    t.string   "name",           limit: 255
    t.string   "slug",           limit: 255
    t.integer  "users_count",    limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "areas", ["ancestry"], name: "index_areas_on_ancestry", using: :btree
  add_index "areas", ["name"], name: "index_areas_on_name", unique: true, using: :btree
  add_index "areas", ["slug"], name: "index_areas_on_slug", unique: true, using: :btree

  create_table "areas_projects", force: :cascade do |t|
    t.integer "area_id",    limit: 4
    t.integer "project_id", limit: 4
  end

  add_index "areas_projects", ["area_id", "project_id"], name: "index_areas_projects_on_area_id_and_project_id", unique: true, using: :btree
  add_index "areas_projects", ["area_id"], name: "index_areas_projects_on_area_id", using: :btree
  add_index "areas_projects", ["project_id"], name: "index_areas_projects_on_project_id", using: :btree

  create_table "areas_users", force: :cascade do |t|
    t.integer "area_id", limit: 4
    t.integer "user_id", limit: 4
  end

  add_index "areas_users", ["area_id", "user_id"], name: "index_areas_users_on_area_id_and_user_id", unique: true, using: :btree
  add_index "areas_users", ["area_id"], name: "index_areas_users_on_area_id", using: :btree
  add_index "areas_users", ["user_id"], name: "index_areas_users_on_user_id", using: :btree

  create_table "candidatures", force: :cascade do |t|
    t.integer  "vacancy_id",    limit: 4
    t.integer  "offeror_id",    limit: 4
    t.string   "name",          limit: 255
    t.string   "slug",          limit: 255
    t.text     "text",          limit: 65535
    t.string   "state",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "resource_type", limit: 255
    t.integer  "resource_id",   limit: 4
  end

  add_index "candidatures", ["resource_id", "resource_type", "vacancy_id"], name: "index_candidatures_on_resource_and_vacancy", unique: true, using: :btree
  add_index "candidatures", ["slug"], name: "index_candidatures_on_slug", unique: true, using: :btree
  add_index "candidatures", ["vacancy_id", "name"], name: "index_candidatures_on_vacancy_id_and_name", unique: true, using: :btree
  add_index "candidatures", ["vacancy_id"], name: "index_candidatures_on_vacancy_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.string   "commentable_type", limit: 255
    t.integer  "commentable_id",   limit: 4
    t.integer  "user_id",          limit: 4
    t.string   "ancestry",         limit: 255
    t.integer  "ancestry_depth",   limit: 4,     default: 0
    t.integer  "position",         limit: 4
    t.string   "name",             limit: 255
    t.text     "text",             limit: 65535
    t.string   "state",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["ancestry"], name: "index_comments_on_ancestry", using: :btree
  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 40
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", unique: true, using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "likes", force: :cascade do |t|
    t.boolean  "positive",    limit: 1,  default: true
    t.integer  "target_id",   limit: 4
    t.string   "target_type", limit: 60,                null: false
    t.integer  "user_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "likes", ["target_id", "user_id", "target_type"], name: "index_likes_on_target_id_and_user_id_and_target_type", unique: true, using: :btree

  create_table "list_items", force: :cascade do |t|
    t.integer  "list_id",    limit: 4
    t.integer  "user_id",    limit: 4
    t.string   "thing_type", limit: 255
    t.integer  "thing_id",   limit: 4
    t.integer  "position",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lists", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lists", ["user_id"], name: "index_lists_on_user_id", using: :btree

  create_table "mongo_db_documents", force: :cascade do |t|
    t.string   "mongo_db_object_id", limit: 255
    t.string   "klass_name",         limit: 255
    t.string   "name",               limit: 255
    t.string   "slug",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mongo_db_documents", ["mongo_db_object_id", "klass_name"], name: "index_mongo_db_documents_on_mongo_db_object_id_and_klass_name", unique: true, using: :btree

  create_table "music_artists", force: :cascade do |t|
    t.string   "mbid",           limit: 255
    t.string   "name",           limit: 255
    t.integer  "listeners",      limit: 4
    t.integer  "plays",          limit: 4
    t.datetime "founded_at"
    t.datetime "dissolved_at"
    t.string   "state",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country",        limit: 255
    t.string   "disambiguation", limit: 255
    t.boolean  "is_ambiguous",   limit: 1
  end

  add_index "music_artists", ["mbid"], name: "index_music_artists_on_mbid", unique: true, using: :btree

  create_table "music_library_artists", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "artist_id",  limit: 4
    t.integer  "plays",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "music_library_artists", ["user_id"], name: "user_id", using: :btree

  create_table "music_metadata_enrichment_group_artist_connections", force: :cascade do |t|
    t.integer  "group_id",       limit: 4
    t.integer  "artist_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "likes_count",    limit: 4, default: 0
    t.integer  "dislikes_count", limit: 4, default: 0
  end

  create_table "music_metadata_enrichment_group_memberships", force: :cascade do |t|
    t.integer  "group_id",   limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "music_metadata_enrichment_group_memberships", ["group_id", "user_id"], name: "uniq_music_metadata_enrichment_group_membership", using: :btree

  create_table "music_metadata_enrichment_group_year_in_review", force: :cascade do |t|
    t.integer  "group_id",    limit: 4
    t.integer  "year",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "users_count", limit: 4
  end

  add_index "music_metadata_enrichment_group_year_in_review", ["group_id", "year"], name: "uniq_music_metadata_enrichment_group_year_in_review", using: :btree

  create_table "music_metadata_enrichment_group_year_in_review_releases", force: :cascade do |t|
    t.integer  "year_in_review_music_id", limit: 4
    t.integer  "group_id",                limit: 4
    t.integer  "year",                    limit: 4
    t.integer  "position",                limit: 4
    t.float    "score",                   limit: 24
    t.integer  "artist_id",               limit: 4
    t.string   "artist_name",             limit: 255
    t.integer  "release_id",              limit: 4
    t.string   "release_name",            limit: 255
    t.datetime "released_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "spotify_album_id",        limit: 22
  end

  add_index "music_metadata_enrichment_group_year_in_review_releases", ["year_in_review_music_id", "position"], name: "uniq_music_metadata_enrichment_group_year_in_review_release", using: :btree

  create_table "music_metadata_enrichment_group_year_in_review_tracks", force: :cascade do |t|
    t.integer  "year_in_review_music_id", limit: 4
    t.integer  "group_id",                limit: 4
    t.integer  "year",                    limit: 4
    t.integer  "position",                limit: 4
    t.float    "score",                   limit: 24
    t.integer  "artist_id",               limit: 4
    t.string   "artist_name",             limit: 255
    t.integer  "release_id",              limit: 4
    t.string   "release_name",            limit: 255
    t.integer  "track_id",                limit: 4
    t.string   "spotify_track_id",        limit: 22
    t.string   "track_name",              limit: 255
    t.datetime "released_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "music_metadata_enrichment_group_year_in_review_tracks", ["year_in_review_music_id", "position"], name: "uniq_music_metadata_enrichment_group_year_in_review_track", using: :btree

  create_table "music_metadata_enrichment_groups", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.integer  "user_id",              limit: 4
    t.string   "current_user_name",    limit: 255
    t.integer  "current_members_page", limit: 4
    t.integer  "synced",               limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "music_releases", force: :cascade do |t|
    t.string   "mbid",                limit: 255
    t.integer  "artist_id",           limit: 4
    t.string   "artist_name",         limit: 255
    t.string   "name",                limit: 255
    t.integer  "tracks_count",        limit: 4
    t.string   "future_release_date", limit: 255
    t.datetime "released_at"
    t.integer  "listeners",           limit: 4
    t.integer  "plays",               limit: 4
    t.integer  "user_id",             limit: 4
    t.string   "state",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_lp",               limit: 1,   default: false, null: false
    t.string   "spotify_album_id",    limit: 22
  end

  add_index "music_releases", ["artist_id"], name: "index_music_releases_on_artist_id", using: :btree
  add_index "music_releases", ["mbid"], name: "index_music_releases_on_mbid", unique: true, using: :btree
  add_index "music_releases", ["released_at"], name: "released_at", using: :btree

  create_table "music_tracks", force: :cascade do |t|
    t.string   "mbid",             limit: 255
    t.integer  "artist_id",        limit: 4
    t.string   "artist_name",      limit: 255
    t.integer  "release_id",       limit: 4
    t.string   "release_name",     limit: 255
    t.integer  "master_track_id",  limit: 4
    t.integer  "nr",               limit: 4
    t.string   "name",             limit: 255
    t.integer  "duration",         limit: 4
    t.integer  "listeners",        limit: 4
    t.integer  "plays",            limit: 4
    t.string   "state",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "released_at"
    t.string   "spotify_track_id", limit: 22
  end

  add_index "music_tracks", ["artist_id"], name: "artist_id", using: :btree
  add_index "music_tracks", ["release_id", "name"], name: "index_music_tracks_on_release_id_and_name", unique: true, using: :btree
  add_index "music_tracks", ["released_at"], name: "released_at", using: :btree

  create_table "music_videos", force: :cascade do |t|
    t.string   "status",         limit: 255
    t.integer  "artist_id",      limit: 4
    t.string   "artist_name",    limit: 255
    t.integer  "track_id",       limit: 4
    t.string   "track_name",     limit: 255
    t.string   "url",            limit: 255
    t.string   "location",       limit: 255
    t.datetime "recorded_at"
    t.integer  "user_id",        limit: 4
    t.string   "state",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "likes_count",    limit: 4,   default: 0
    t.integer  "dislikes_count", limit: 4,   default: 0
  end

  add_index "music_videos", ["status", "track_id"], name: "index_music_videos_on_type_and_track_id", unique: true, using: :btree
  add_index "music_videos", ["track_id"], name: "index_music_videos_on_track_id", using: :btree
  add_index "music_videos", ["url"], name: "index_music_videos_on_url", unique: true, using: :btree

  create_table "organizations", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "slug",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    limit: 4
  end

  add_index "organizations", ["slug"], name: "index_organizations_on_slug", using: :btree

  create_table "professions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "slug",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", force: :cascade do |t|
    t.integer  "user_id",         limit: 4
    t.string   "name",            limit: 255
    t.string   "slug",            limit: 255
    t.text     "text",            limit: 65535
    t.string   "url",             limit: 255
    t.string   "state",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "product_id",      limit: 255
    t.integer  "organization_id", limit: 4
  end

  add_index "projects", ["organization_id"], name: "index_projects_on_organization_id", using: :btree
  add_index "projects", ["product_id"], name: "index_projects_on_product_id", using: :btree
  add_index "projects", ["slug"], name: "index_projects_on_slug", unique: true, using: :btree
  add_index "projects", ["user_id"], name: "index_projects_on_user_id", using: :btree

  create_table "projects_users", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "vacancy_id", limit: 4
    t.integer "role_id",    limit: 4
    t.integer "user_id",    limit: 4
    t.string  "state",      limit: 255
  end

  add_index "projects_users", ["project_id", "user_id", "vacancy_id"], name: "index_projects_users_on_project_id_and_user_id_and_vacancy_id", unique: true, using: :btree
  add_index "projects_users", ["project_id"], name: "index_projects_users_on_project_id", using: :btree
  add_index "projects_users", ["role_id"], name: "index_projects_users_on_role_id", using: :btree
  add_index "projects_users", ["user_id"], name: "index_projects_users_on_user_id", using: :btree
  add_index "projects_users", ["vacancy_id"], name: "index_projects_users_on_vacancy_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "state",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",     limit: 1,   default: false
    t.string   "type",       limit: 255
  end

  create_table "things", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "things", ["name"], name: "index_things_on_name", unique: true, using: :btree

  create_table "user_music_track_matches", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.integer  "left_id",    limit: 4
    t.integer  "right_id",   limit: 4
    t.integer  "winner_id",  limit: 4
    t.integer  "loser_id",   limit: 4
    t.string   "state",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_music_track_matches", ["state"], name: "index_user_music_track_matches_on_state", using: :btree
  add_index "user_music_track_matches", ["user_id"], name: "index_user_music_track_matches_on_user_id", using: :btree
  add_index "user_music_track_matches", ["winner_id"], name: "index_user_music_track_matches_on_winner_id", using: :btree

  create_table "user_music_track_rankings", force: :cascade do |t|
    t.integer  "user_id",           limit: 4
    t.integer  "track_id",          limit: 4
    t.integer  "won_matches_count", limit: 4, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_music_track_rankings", ["user_id"], name: "index_user_music_track_rankings_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                    limit: 255
    t.string   "slug",                    limit: 255
    t.string   "rpx_identifier",          limit: 255
    t.string   "password",                limit: 255
    t.text     "text",                    limit: 65535
    t.text     "serialized_private_key",  limit: 65535
    t.string   "language",                limit: 255
    t.string   "first_name",              limit: 255
    t.string   "last_name",               limit: 255
    t.string   "salutation",              limit: 255
    t.string   "marital_status",          limit: 255
    t.string   "family_status",           limit: 255
    t.date     "date_of_birth"
    t.string   "place_of_birth",          limit: 255
    t.string   "citizenship",             limit: 255
    t.string   "email",                   limit: 255,   default: ""
    t.string   "encrypted_password",      limit: 255,   default: "",    null: false
    t.string   "reset_password_token",    limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           limit: 4,     default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",      limit: 255
    t.string   "last_sign_in_ip",         limit: 255
    t.string   "confirmation_token",      limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",       limit: 255
    t.integer  "failed_attempts",         limit: 4,     default: 0
    t.string   "unlock_token",            limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",    limit: 255
    t.string   "password_salt",           limit: 255
    t.boolean  "music_library_imported",  limit: 1,     default: false
    t.string   "state",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country",                 limit: 255
    t.string   "interface_language",      limit: 255
    t.string   "employment_relationship", limit: 255
    t.integer  "profession_id",           limit: 4
    t.integer  "main_role_id",            limit: 4
    t.text     "foreign_languages",       limit: 65535
    t.string   "provider",                limit: 255
    t.string   "uid",                     limit: 255
    t.string   "lastfm_user_name",        limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["name"], name: "index_users_on_name", unique: true, using: :btree
  add_index "users", ["profession_id"], name: "index_users_on_profession_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree

  create_table "users_roles", force: :cascade do |t|
    t.integer "role_id", limit: 4
    t.integer "user_id", limit: 4
    t.string  "state",   limit: 255
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true, using: :btree

  create_table "vacancies", force: :cascade do |t|
    t.string   "type",            limit: 255
    t.integer  "project_id",      limit: 4
    t.integer  "offeror_id",      limit: 4
    t.integer  "author_id",       limit: 4
    t.integer  "project_user_id", limit: 4
    t.string   "name",            limit: 255
    t.string   "slug",            limit: 255
    t.text     "text",            limit: 65535
    t.integer  "limit",           limit: 4,     default: 1
    t.string   "state",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "resource_type",   limit: 255
    t.integer  "resource_id",     limit: 4
  end

  add_index "vacancies", ["offeror_id"], name: "index_vacancies_on_offeror_id", using: :btree
  add_index "vacancies", ["project_id", "name"], name: "index_vacancies_on_project_id_and_name", unique: true, using: :btree
  add_index "vacancies", ["project_id"], name: "index_vacancies_on_project_id", using: :btree
  add_index "vacancies", ["project_user_id"], name: "index_vacancies_on_project_user_id", using: :btree
  add_index "vacancies", ["slug"], name: "index_vacancies_on_slug", unique: true, using: :btree

  create_table "year_in_review_music", force: :cascade do |t|
    t.integer  "user_id",             limit: 4
    t.integer  "year",                limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "top_track_matches",   limit: 65535
    t.text     "top_release_matches", limit: 65535
    t.string   "state",               limit: 255,   default: "draft"
  end

  add_index "year_in_review_music", ["user_id", "year"], name: "index_year_in_review_music_on_user_id_and_year", using: :btree

  create_table "year_in_review_music_release_flops", force: :cascade do |t|
    t.integer  "year_in_review_music_id", limit: 4
    t.integer  "user_id",                 limit: 4
    t.integer  "year",                    limit: 4
    t.integer  "artist_id",               limit: 4
    t.string   "artist_name",             limit: 255
    t.integer  "release_id",              limit: 4
    t.string   "release_name",            limit: 255
    t.datetime "released_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "spotify_album_id",        limit: 22
  end

  add_index "year_in_review_music_release_flops", ["year_in_review_music_id", "release_id"], name: "year_in_review_music_release_flop_releases", using: :btree

  create_table "year_in_review_music_releases", force: :cascade do |t|
    t.integer  "year_in_review_music_id", limit: 4
    t.integer  "user_id",                 limit: 4
    t.integer  "year",                    limit: 4
    t.integer  "position",                limit: 4
    t.integer  "artist_id",               limit: 4
    t.string   "artist_name",             limit: 255
    t.integer  "release_id",              limit: 4
    t.string   "release_name",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "released_at"
    t.string   "spotify_album_id",        limit: 22
    t.string   "state",                   limit: 255, default: "draft"
  end

  add_index "year_in_review_music_releases", ["year_in_review_music_id", "position"], name: "uniq_year_in_review_music_release", using: :btree

  create_table "year_in_review_music_track_flops", force: :cascade do |t|
    t.integer  "year_in_review_music_id", limit: 4
    t.integer  "user_id",                 limit: 4
    t.integer  "year",                    limit: 4
    t.integer  "artist_id",               limit: 4
    t.string   "artist_name",             limit: 255
    t.integer  "release_id",              limit: 4
    t.string   "release_name",            limit: 255
    t.integer  "track_id",                limit: 4
    t.string   "spotify_track_id",        limit: 22
    t.string   "track_name",              limit: 255
    t.datetime "released_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "year_in_review_music_track_flops", ["year_in_review_music_id", "track_id"], name: "year_in_review_music_release_flop_tracks", using: :btree

  create_table "year_in_review_music_tracks", force: :cascade do |t|
    t.integer  "year_in_review_music_id", limit: 4
    t.integer  "user_id",                 limit: 4
    t.integer  "year",                    limit: 4
    t.integer  "position",                limit: 4
    t.integer  "artist_id",               limit: 4
    t.string   "artist_name",             limit: 255
    t.integer  "release_id",              limit: 4
    t.string   "release_name",            limit: 255
    t.integer  "track_id",                limit: 4
    t.string   "spotify_track_id",        limit: 22
    t.string   "track_name",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "released_at"
    t.string   "state",                   limit: 255, default: "draft"
  end

  add_index "year_in_review_music_tracks", ["year_in_review_music_id", "position"], name: "uniq_year_in_review_music_track", using: :btree

end
