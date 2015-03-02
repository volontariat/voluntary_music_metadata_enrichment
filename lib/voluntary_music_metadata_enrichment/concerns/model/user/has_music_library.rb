module VoluntaryMusicMetadataEnrichment
  module Concerns
    module Model
      module User
        module HasMusicLibrary
          extend ActiveSupport::Concern
          
          included do
            has_many :years_in_review_music, class_name: 'YearInReviewMusic', dependent: :destroy
            has_many :years_in_review_music_releases, class_name: 'YearInReviewMusicRelease', through: :years_in_review_music, source: 'releases'
            has_many :years_in_review_music_tracks, class_name: 'YearInReviewMusicTrack', through: :years_in_review_music, source: 'tracks'
            has_many :music_library_artists, dependent: :destroy
            has_many :music_artists, through: :music_library_artists, source: 'artist'
            has_many :music_releases, through: :music_artists, source: 'releases'
            has_many :music_tracks, through: :music_artists, source: 'tracks'
            has_many :music_videos, through: :music_artists, source: 'videos'
                        
            scope :on_lastfm, -> { where('users.lastfm_user_name IS NOT NULL') }
            
            after_destroy :nullify_user_association_at_videos
          end
          
          def import_music_artists(lastfm, start_page = 1)
            artist_names, artist_mbids = [], []
            
            1000.times do |page|
              page +=1
              
              next unless page >= start_page
              
              lastfm_artists = nil
              
              begin
                lastfm_artists = MusicArtist.lastfm_request_class_method(
                  lastfm, :library, :get_artists, nil, user: lastfm_user_name, page: page, raise_parse_exception: true
                )
              rescue REXML::ParseException
                lastfm_artists = []
                puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} COULD NOT BE PARSED"
              end
             
              if lastfm_artists.nil? || lastfm_artists.first.nil?
                puts "USER #{lastfm_user_name}: LIBRARY PAGE ##{page} IS EMPTY" 
                break
              end
              
              mbids_by_artist = {}
              working_artist_names = lastfm_artists.map{|a| a['name'].downcase}.select{|a| !artist_names.include?(a) }
              
              voluntary_artist_names = if working_artist_names.empty?
                lastfm_artists.map{|a| a['name'].downcase}.select{|a| artist_names.include?(a) }
              else
                MusicArtist.select('name').where('LOWER(name) IN(?)', working_artist_names).map{|a| a.name.downcase }
              end
              
              failed_artist_search_names = []
              names_of_artists_without_mbid = []
              
              lastfm_artists.each do |a|
                next if (artist_names + voluntary_artist_names).include?(a['name'].downcase)
                
                if a['mbid'].blank?
                  names_of_artists_without_mbid << a['mbid']
                  artist_names << a['name'].downcase
                  
                  next
                end
                
                next if mbids_by_artist.has_key?(a['name'].downcase)
                
                artists = MusicBrainz::Artist.search(a['name'])
                
                if artists.nil?
                  puts 'MusicBrainz failed: MusicBrainz::Artist.search("' + a['name'] + '")'
                  mbids_by_artist[a['name'].downcase] = []
                  artist_names << a['name'].downcase
                  failed_artist_search_names << a['name'].downcase
                else
                  mbids_by_artist[a['name'].downcase] = artists.select{|a2| a2[:name].downcase == a['name'].downcase}.map{|a| a[:mbid]}
                end
              end
               
              voluntary_artists = MusicArtist.where('mbid IN(?)', mbids_by_artist.values.flatten.uniq).to_a
              
              if failed_artist_search_names.empty? && names_of_artists_without_mbid.empty? && (lastfm_artists.select{|a| a['playcount'].to_i >= 5 && !(artist_names + voluntary_artist_names).include?(a['name'].downcase) && mbids_by_artist[a['name'].downcase].select{|mbid| !artist_mbids.include?(mbid)}.any? }.none? || lastfm_artists.select{|a| a['playcount'].to_i >= 5 }.none?)
                # over last page
                break
              end
  
              lastfm_artists.each do |lastfm_artist|
                next if failed_artist_search_names.include?(lastfm_artist['name'].downcase)
                next if (artist_names + voluntary_artist_names).include?(lastfm_artist['name'].downcase)
                
                current_artist_mbids = mbids_by_artist[lastfm_artist['name'].downcase].select{|mbid| !artist_mbids.include?(mbid)}
                
                if lastfm_artist['playcount'].to_i < 5 || current_artist_mbids.none?
                  next
                else
                  artist_names << lastfm_artist['name'].downcase
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
              
              sleep 3
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