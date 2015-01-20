module VoluntaryMusicMetadataEnrichment
  module Concerns
    module Model
      module User
        module HasMusicLibrary
          extend ActiveSupport::Concern
          
          def import_music_artists(lastfm)
            artist_names = []
            over_last_page = false
            
            1000.times do |page|
              page +=1
              
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
                rescue Lastfm::ApiError
                  puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} ... Lastfm::ApiError ... TRY AGAIN"
                  sleep 30
                end
              end
             
              if lastfm_artists.first.nil?
                puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} IS EMPTY" 
                over_last_page = true
                break
              end
             
              artist_mbids = lastfm_artists.map{|a| a['mbid']}.uniq
              
              voluntary_artist_mbids = MusicArtist.where('mbid IN(?)', artist_mbids).map(&:mbid)
              
              lastfm_artists.each do |lastfm_artist|
                if artist_names.include?(lastfm_artist['name'])
                  over_last_page = true
                  
                  break  
                else
                  artist_names << lastfm_artist['name']
                end
                
                next if lastfm_artist['mbid'].blank?
                
                next if voluntary_artist_mbids.include? lastfm_artist['mbid']
                
                if MusicBrainz::Artist.find(lastfm_artist['mbid'])
                  MusicArtist.create(name: lastfm_artist['name'], mbid: lastfm_artist['mbid'])
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