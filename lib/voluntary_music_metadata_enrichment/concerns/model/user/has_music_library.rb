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
                  lastfm_artists = lastfm.library.get_artists(user: lastfm_user_name, page: page)
                  
                  puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page}"
                  
                  break
                rescue Lastfm::ApiError
                  sleep 30
                end
              end
              
              lastfm_artists.each do |lastfm_artist|
                if artist_names.include?(lastfm_artist['name'])
                  over_last_page = true
                  
                  break  
                else
                  artist_names << lastfm_artist['name']
                end
                
                next if lastfm_artist['mbid'].blank?
                
                next if MusicArtist.where(mbid: lastfm_artist['mbid']).any?
                
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