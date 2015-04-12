# voluntary_music_metadata_enrichment [![Build Status](https://travis-ci.org/volontariat/voluntary_music_metadata_enrichment.svg?branch=master)](https://travis-ci.org/volontariat/voluntary_music_metadata_enrichment) [![Code Climate](https://codeclimate.com/github/volontariat/voluntary_music_metadata_enrichment/badges/gpa.svg)](https://codeclimate.com/github/volontariat/voluntary_music_metadata_enrichment) [![Test Coverage](https://codeclimate.com/github/volontariat/voluntary_music_metadata_enrichment/badges/coverage.svg)](https://codeclimate.com/github/volontariat/voluntary_music_metadata_enrichment) [![Dependency Status](https://gemnasium.com/volontariat/voluntary_music_metadata_enrichment.png)](https://gemnasium.com/volontariat/voluntary_music_metadata_enrichment)

A plugin for crowdsourcing management system http://Voluntary.Software which adds a music model with discography sync through http://MusicBrainz.org, http://last.fm plus http://Spotify.com to every Ruby on Rails application. But it does not import everything: see [Which data will be imported?](https://github.com/volontariat/voluntary_music_metadata_enrichment/wiki/Which-data-will-be-imported%3F).

You can create year in reviews for music albums and songs, read more about it in my blog post @ http://last.fm: [Top Songs 2014 created with Open Source Website Volontari.at](http://www.last.fm/user/Volontarian/journal/2015/03/12/6grdr2_top_songs_2014_created_with_open_source_website_volontari.at)

Furthermore you can manage last.fm groups with artist connections voting, release announcements and music video indexing.

## Installation

Preconditions: install the voluntary gem in your rails application https://GitHub.com/volontariat/voluntary

Add this to your Gemfile:
 
```ruby 
  gem 'voluntary_music_metadata_enrichment'
```
  
Run this in your console:

```bash
  bundle install  
```
  
Run this in your console:

```bash
  rake railties:install:migrations
```
  
## License 

This project uses MIT-LICENSE.