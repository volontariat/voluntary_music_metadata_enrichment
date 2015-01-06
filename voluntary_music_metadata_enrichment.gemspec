$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "voluntary_music_metadata_enrichment/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "voluntary_music_metadata_enrichment"
  s.version     = VoluntaryMusicMetadataEnrichment::VERSION
  s.authors     = ["Mathias Gawlista"]
  s.email       = ["gawlista@gmail.com"]
  s.homepage    = "https://github.com/volontariat/voluntary_music_metadata_enrichment"
  s.summary     = "Music metadata encryption product for crowdsourcing engine voluntary."
  s.description = "Music metadata encryption product for crowdsourcing engine voluntary."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "voluntary", "~> 0.2.1"
end
