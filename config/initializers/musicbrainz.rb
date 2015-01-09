MusicBrainz.configure do |c|
  # Application identity (required)
  c.app_name = "Voluntari.at: Music Metadata Enrichment"
  c.app_version = "0.0.1"
  c.contact = "gawlista@gmail.com"

  # Cache config (optional)
  c.cache_path = "/tmp/musicbrainz-cache"
  c.perform_caching = true

  # Querying config (optional)
  c.query_interval = 1.2 # seconds
  c.tries_limit = 2
end