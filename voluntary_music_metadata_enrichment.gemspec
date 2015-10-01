$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'voluntary_music_metadata_enrichment/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'voluntary_music_metadata_enrichment'
  s.version     = VoluntaryMusicMetadataEnrichment::VERSION
  s.authors     = ['Mathias Gawlista']
  s.email       = ['gawlista@gmail.com']
  s.homepage    = 'http://Volontari.at/music'
  s.summary     = 'Music metadata enrichment plugin for crowdsourcing management system Voluntary.Software.'
  s.description = 'Importer, year in reviews, videos, etc. - changes: bit.ly/vmme-0-2-0'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md', 'CHANGELOG.md']

  s.add_dependency 'voluntary', '~> 0.5'
  
  s.add_dependency 'musicbrainz'
  s.add_dependency 'lastfm', '~> 1.27.0'
  
  # group :development
  s.add_development_dependency 'letter_opener', '~> 1.0.0'

  # for tracing AR object instantiation and memory usage per request
  s.add_development_dependency 'oink', '~> 0.10.1'

  # group :development, :test
  s.add_development_dependency 'awesome_print', '~> 1.1.0'
  s.add_development_dependency 'rspec-rails', '~> 2.0' 
  
  # group :test
  s.add_development_dependency 'capybara', '~> 1.1.2'
  s.add_development_dependency 'capybara-webkit', '~> 0.13.0'
  s.add_development_dependency 'cucumber-rails-training-wheels', '~> 1.0.0'
  s.add_development_dependency 'timecop', '~> 0.6.1'
  s.add_development_dependency 'factory_girl_rails', '~> 1.7.0'
  s.add_development_dependency 'fixture_builder', '~> 0.3.3'
  s.add_development_dependency 'selenium-webdriver', '~> 2.22.1'
  s.add_development_dependency 'spork', '~> 1.0rc2'
  s.add_development_dependency 'guard-rspec', '~> 3.0.2'
  s.add_development_dependency 'guard-spork', '~> 1.5.1'
  s.add_development_dependency 'guard-cucumber', '~> 1.4.0'
  s.add_development_dependency 'launchy', '~> 2.1.2'

  # group :cucumber, :test
  s.add_development_dependency 'database_cleaner', '~> 0.7.1'
end
