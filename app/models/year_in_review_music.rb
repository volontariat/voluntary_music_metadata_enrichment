class YearInReviewMusic < ActiveRecord::Base
  self.table_name = 'year_in_review_music'
  
  belongs_to :user
  
  has_many :releases, class_name: 'YearInReviewMusicRelease', dependent: :delete_all
  has_many :flop_releases, class_name: 'YearInReviewMusicReleaseFlop', dependent: :delete_all
  has_many :tracks, class_name: 'YearInReviewMusicTrack', dependent: :delete_all
  has_many :flop_tracks, class_name: 'YearInReviewMusicTrackFlop', dependent: :delete_all
  
  validates :user_id, presence: true
  validates :year, presence: true, numericality: { only_integer: true }, uniqueness: { scope: :user_id }
  
  attr_accessible :user_id, :year
  
  def self.initialize_by_lastfm(user, year = nil)
    return if user.lastfm_user_name.blank?
    
    lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
    [
      initialize_top_releases_by_lastfm(lastfm, user, year), 
      initialize_top_tracks_by_lastfm(lastfm, user, year)
    ]
  end
  
  def self.initialize_top_releases_by_lastfm(lastfm, user, year = nil)
    lastfm_user_name, working_releases, missing_releases = user.lastfm_user_name, [], []
    year_in_reviews = {}
    
    1000.times do |page|
      page +=1
      lastfm_albums = nil
      
      3.times do
        begin
          begin
            period = if year.present? && Time.local(year, 1, 1) > 15.months.ago
              '12month'
            else
              'overall'
            end
            
            lastfm_albums = lastfm.user.get_top_albums(user: lastfm_user_name, period: period, page: page)
            
            puts "USER #{lastfm_user_name}: TOP ALBUMS PAGE ##{page}"
          rescue REXML::ParseException
            lastfm_albums = []
            puts "USER #{lastfm_user_name}: TOP ALBUMS PAGE ##{page} COULD NOT BE PARSED"
          end
          
          break
        rescue Lastfm::ApiError, Timeout::Error => e
          puts "USER #{lastfm_user_name}: TOP ALBUMS PAGE ##{page} ... #{e.class.name}... TRY AGAIN"
          sleep 30
        end
      end
     
      if lastfm_albums.nil? || lastfm_albums.first.nil?
        puts "USER #{lastfm_user_name}: TOP ALBUMS PAGE ##{page} IS EMPTY" 
        break
      end
      
      if lastfm_albums.select{|a| !working_releases.include?([a['artist']['name'], a['name']])}.none?
        # over last page
        break
      end
      
      break if lastfm_albums.select{|a| a['playcount'].to_i >= 20 }.none?
        
      lastfm_albums.each do |lastfm_album|
        next if lastfm_album['playcount'].to_i < 20
        
        album_name = MusicRelease.format_lastfm_name(lastfm_album['name'])
        working_release = [lastfm_album['artist']['name'], album_name]
        
        if working_releases.include?(working_release)
          next
        else
          working_releases << working_release
        end
        
        music_releases = MusicRelease.by_artist_and_name(lastfm_album['artist']['name'], album_name)
        music_releases_count = music_releases.count
        
        if music_releases_count == 0
          lastfm_album_info = nil
          
          begin
            lastfm_album_info = lastfm.album.get_info(artist: lastfm_album['artist']['name'], album: album_name)
          rescue Lastfm::ApiError
            lastfm_album_info = lastfm.album.get_info(artist: lastfm_album['artist']['name'], album: lastfm_album['name'])
          end
          
          if year.present?
            next unless (lastfm_album_info['releasedate'].blank? || Time.parse(lastfm_album_info['releasedate']).strftime('%Y').to_i == year)
          end
          
          missing_releases << { 
            rank: lastfm_album['rank'], artist_name: lastfm_album['artist']['name'], name: album_name,
            released_at: lastfm_album_info['releasedate'].blank? ? '' : Time.parse(lastfm_album_info['releasedate']).strftime('%d.%m.%Y')
          }
          
          next
        end
        
        if music_releases.select{|r| r.released_at.present? }.any?
          music_releases = music_releases.select{|r| r.released_at.present? }
        end
        
        music_releases.each do |release|
          if year.present? && release.released_at.present? && release.released_at.strftime('%Y').to_i != year
            next
          elsif release.released_at.blank?
            lastfm_album_info = lastfm.album.get_info(artist: lastfm_album['artist']['name'], album: lastfm_album['name'])
            
            release.update_attribute(:released_at, Time.parse(lastfm_album_info['releasedate'])) if lastfm_album_info['releasedate'].present?
            
            if release.released_at.blank?
              missing_releases << { 
                rank: lastfm_album['rank'], artist_name: lastfm_album['artist']['name'], name: album_name, is_lp: release.is_lp
              }
              next  
            end
            
            next unless year.blank? || release.released_at.strftime('%Y').to_i == year
          end
          
          current_year = release.released_at.strftime('%Y').to_i
          
          next if Time.local(current_year, 1, 1) < 15.months.ago && lastfm_album['playcount'].to_i < 50
          
          MusicLibraryArtist.create(user_id: user.id, artist_id: release.artist_id)
          
          unless year_in_reviews[current_year]
            year_in_review = user.years_in_review_music.where(year: current_year).first
            
            year_in_review.releases.delete_all if year_in_review
            year_in_review = user.years_in_review_music.create!(year: current_year) unless year_in_review
            
            year_in_reviews[current_year] = year_in_review
          end

          year_in_reviews[current_year].releases.create!(release_id: release.id)
        end
      end
    end
    
    missing_releases
  end
  
  def self.initialize_top_tracks_by_lastfm(lastfm, user, year = nil)
    lastfm_user_name, working_tracks, missing_tracks, lastfm_albums = user.lastfm_user_name, [], [], {}
    year_in_reviews = {}
    
    1000.times do |page|
      page +=1
      lastfm_tracks = nil
      
      3.times do
        begin
          begin
            period = if year.present? && Time.local(year, 1, 1) > 15.months.ago
              '12month'
            else
              'overall'
            end
            
            lastfm_tracks = lastfm.user.get_top_tracks(user: lastfm_user_name, period: period, page: page)
            
            puts "USER #{lastfm_user_name}: TOP TRACKS PAGE ##{page}"
          rescue REXML::ParseException
            lastfm_tracks = []
            puts "USER #{lastfm_user_name}: TOP TRACKS PAGE ##{page} COULD NOT BE PARSED"
          end
          
          break
        rescue Lastfm::ApiError, Timeout::Error => e
          puts "USER #{lastfm_user_name}: TOP TRACKS PAGE ##{page} ... #{e.class.name}... TRY AGAIN"
          sleep 30
        end
      end
     
      if lastfm_tracks.nil? || lastfm_tracks.first.nil?
        puts "USER #{lastfm_user_name}: TOP TRACKS PAGE ##{page} IS EMPTY" 
        break
      end
      
      if lastfm_tracks.select{|a| !working_tracks.include?([a['artist']['name'], a['name']])}.none?
        # over last page
        break
      end
      
      break if lastfm_tracks.select{|a| a['playcount'].to_i >= 3 }.none?
        
      lastfm_tracks.each do |lastfm_track|
        next if lastfm_track['playcount'].to_i < 3
        
        working_track = [lastfm_track['artist']['name'], lastfm_track['name']]
        
        if working_tracks.include?(working_track)
          next
        else
          working_tracks << working_track
        end
        
        music_tracks = MusicTrack.by_artist_and_name(lastfm_track['artist']['name'], lastfm_track['name'])
        
        if music_tracks.count == 0
          lastfm_track_info = lastfm.track.get_info(artist: lastfm_track['artist']['name'], track: lastfm_track['name'])
          
          lastfm_album_info = if lastfm_track_info['album'].nil? || lastfm_track_info['album']['artist'].downcase != lastfm_track['artist']['name']
            {}
          else
            ::YearInReviewMusic.get_lastfm_album(lastfm, lastfm_track['artist']['name'], lastfm_track_info['album']['title'], lastfm_albums)
          end
          
          released_at = nil
          released_at = lastfm_album_info['releasedate'] if lastfm_album_info['releasedate'].present?
          
          if year.present?
            next unless (released_at.blank? || Time.parse(released_at).strftime('%Y').to_i == year)
          end
          
          missing_tracks << { 
            rank: lastfm_track['rank'], artist_name: lastfm_track['artist']['name'], name: lastfm_track['name'],
            released_at: released_at.blank? ? '' : Time.parse(released_at).strftime('%d.%m.%Y')
          }
          
          next
        end
        
        if music_tracks.select{|t| t.released_at.present? }.any?
          music_tracks = music_tracks.select{|t| t.released_at.present? }
        end
        
        music_tracks.each do |track|
          if year.present? && track.released_at.present? && track.released_at.strftime('%Y').to_i != year
            next
          elsif track.released_at.blank?
            lastfm_track_info = lastfm.track.get_info(artist: lastfm_track['artist']['name'], track: lastfm_track['name'])
            
            lastfm_album_info = if lastfm_track_info['album'].nil? || lastfm_track_info['album']['artist'].downcase != lastfm_track['artist']['name']
              {}
            else
              ::YearInReviewMusic.get_lastfm_album(lastfm, lastfm_track['artist']['name'], lastfm_track_info['album']['title'], lastfm_albums)
            end
            
            released_at = nil
            released_at = lastfm_album_info['releasedate'] if lastfm_album_info['releasedate'].present?
            
            if released_at.present?
              track.update_attribute(:released_at, Time.parse(released_at))
            else
              missing_tracks << { 
                rank: lastfm_track['rank'], artist_name: lastfm_track['artist']['name'], name: lastfm_track['name']
              }
              break
            end
            
            next unless year.blank? || Time.parse(released_at).strftime('%Y').to_i == year
          end
        
          current_year = track.released_at.strftime('%Y').to_i
          
          next if Time.local(current_year, 1, 1) < 15.months.ago && lastfm_track['playcount'].to_i < 10
          
          MusicLibraryArtist.create(user_id: user.id, artist_id: track.artist_id)
          
          unless year_in_reviews[current_year]
            year_in_review = user.years_in_review_music.where(year: current_year).first
            
            year_in_review.tracks.delete_all if year_in_review
            year_in_review = user.years_in_review_music.create!(year: current_year) unless year_in_review
            
            year_in_reviews[current_year] = year_in_review
          end

          year_in_reviews[current_year].tracks.create!(track_id: track.id)
        end
      end
    end
    
    missing_tracks
  end
  
  def self.get_lastfm_album(lastfm, artist_name, name, lastfm_albums)
    lastfm_album_key = "#{artist_name} - #{MusicRelease.format_lastfm_name(name)}"
    
    if lastfm_albums[lastfm_album_key]
      lastfm_albums[lastfm_album_key]
    else
      lastfm_album_info = lastfm.album.get_info(artist: artist_name, album: name)
      
      if lastfm_album_info['releasedate'].blank?
        begin
          lastfm_album_info = lastfm.album.get_info(artist: artist_name, album: MusicRelease.format_lastfm_name(name))
        rescue Lastfm::ApiError
        end
      end
      
      lastfm_albums[lastfm_album_key] = lastfm_album_info
      lastfm_album_info
    end
  end
  
  def initialize_by_lastfm
    ::YearInReviewMusic.initialize_by_lastfm(user, year)
  end
end