module VoluntaryMusicMetadataEnrichment
  module Concerns
    module Model
      module User
        module HasMusicLibrary
          extend ActiveSupport::Concern
          
          included do
            has_many :music_library_artists
            has_many :music_artists, through: :music_library_artists, source: 'artist'
            has_many :music_releases, through: :music_artists, source: 'releases'
            has_many :music_tracks, through: :music_artists, source: 'tracks'
                        
            scope :on_lastfm, -> { where('users.lastfm_user_name IS NOT NULL') }
          end
          
          def import_music_artists(lastfm, start_page = 1)
            artist_names = []
            over_last_page = false
            
            1000.times do |page|
              page +=1
              
              next unless page >= start_page
              
              lastfm_artists = nil
              
              3.times do
                begin
                  begin
                    lastfm_artists = lastfm.library.get_artists(user: lastfm_user_name, page: page)
                    
                    puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page}"
                  rescue REXML::ParseException
                    lastfm_artists = []
                    puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} COULD NOT BE PARSED"
                  end
                  
                  break
                rescue Lastfm::ApiError, Timeout::Error => e
                  puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} ... #{e.class.name}... TRY AGAIN"
                  sleep 30
                end
              end
             
              if lastfm_artists.nil? || lastfm_artists.first.nil?
                puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} IS EMPTY" 
                over_last_page = true
                break
              end
             
              artist_mbids = lastfm_artists.map{|a| a['mbid']}.uniq
              
              voluntary_artists = MusicArtist.where('mbid IN(?)', artist_mbids).to_a
              
              lastfm_artists.each do |lastfm_artist|
                if artist_names.include?(lastfm_artist['name'])
                  over_last_page = true
                  
                  break  
                else
                  artist_names << lastfm_artist['name']
                end
                
                next if lastfm_artist['mbid'].blank?
                
                artist = nil
                
                unless artist = voluntary_artists.select{|a| a.mbid == lastfm_artist['mbid'] }.first
                  if MusicBrainz::Artist.find(lastfm_artist['mbid'])
                    artist = MusicArtist.create(name: lastfm_artist['name'], mbid: lastfm_artist['mbid'])
                  end
                end
                
                if artist
                  music_library_artists.create(artist_id: artist.id, plays: lastfm_artist['playcount']) unless new_record?
                end
              end
              
              break if over_last_page
            end
            
            update_attribute(:music_library_imported, true) unless new_record?
          end
        end
      end
    end
  end
end