module VoluntaryMusicMetadataEnrichment
  module Concerns
    module Model
      module User
        module HasMusicLibrary
          extend ActiveSupport::Concern
          
          included do
            has_many :years_in_review_music, class_name: 'YearInReviewMusic', dependent: :destroy
            has_many :music_library_artists, dependent: :destroy
            has_many :music_artists, through: :music_library_artists, source: 'artist'
            has_many :music_releases, through: :music_artists, source: 'releases'
            has_many :music_tracks, through: :music_artists, source: 'tracks'
            has_many :music_videos, through: :music_artists, source: 'videos'
                        
            scope :on_lastfm, -> { where('users.lastfm_user_name IS NOT NULL') }
            
            after_destroy :nullify_user_association_at_videos
          end
          
          def import_music_artists(lastfm, start_page = 1)
            artist_mbids = []
            
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
                break
              end
              
              mbids_by_artist = {}
              
              lastfm_artists.each do |a|
                mbids_by_artist[a['name'].downcase] ||= MusicBrainz::Artist.search(a['name']).select{|a2| a2[:name].downcase == a['name'].downcase}.map{|a| a[:mbid]}
              end
               
              voluntary_artists = MusicArtist.where('mbid IN(?)', mbids_by_artist.values.flatten.uniq).to_a
              
              if lastfm_artists.select{|a| a['playcount'].to_i >= 5 && mbids_by_artist[a['name'].downcase].select{|mbid| !artist_mbids.include?(mbid)}.any? }.none? || lastfm_artists.select{|a| a['playcount'].to_i >= 5 }.none?
                # over last page
                break
              end
  
              lastfm_artists.each do |lastfm_artist|
                current_artist_mbids = mbids_by_artist[lastfm_artist['name'].downcase].select{|mbid| !artist_mbids.include?(mbid)}
                
                if lastfm_artist['playcount'].to_i < 5 || current_artist_mbids.none?
                  next
                else
                  artist_mbids += current_artist_mbids
                end
                
                next if lastfm_artist['mbid'].blank?
                
                current_artist_mbids.each do |mbid|
                  artist = nil
                   
                  unless artist = voluntary_artists.select{|a| a.mbid == mbid }.first
                    artist = MusicArtist.create(name: lastfm_artist['name'], mbid: mbid, is_ambiguous: mbids_by_artist[lastfm_artist['name'].downcase].length > 1)
                  end
                  
                  if artist.persisted?
                    music_library_artists.create(artist_id: artist.id, plays: lastfm_artist['playcount']) unless new_record?
                  end
                end
              end
            end
            
            update_attribute(:music_library_imported, true) unless new_record?
          end
          
          private
          
          def nullify_user_association_at_videos
            MusicVideo.where(user_id: id).update_all("user_id = NULL")
          end
        end
      end
    end
  end
end