module MusicMetadataEnrichment
  class Group < ActiveRecord::Base
    self.table_name = 'music_metadata_enrichment_groups'
    
    has_many :artist_connections, class_name: 'MusicMetadataEnrichment::GroupArtistConnection', foreign_key: 'group_id', dependent: :destroy
    has_many :artists, class_name: 'MusicArtist', through: :artist_connections
    has_many :releases, class_name: 'MusicRelease', through: :artists
    has_many :videos, class_name: 'MusicVideo', through: :artists
    has_many :memberships, class_name: 'MusicMetadataEnrichment::GroupMembership', foreign_key: 'group_id', dependent: :destroy
    has_many :members, class_name: 'User', through: :memberships, source: 'user'
    has_many :year_in_reviews, class_name: 'MusicMetadataEnrichment::GroupYearInReview', dependent: :destroy
    has_many :year_in_reviews_of_members, class_name: 'YearInReviewMusic', through: :members, source: 'years_in_review_music'
    
    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validate :registered_on_lastfm
    
    attr_accessible :name, :artist_connections_text
    
    attr_accessor :user_id, :artist_connections_text
    
    after_create :create_first_member
    
    def import_artist_connections
      artist_names_without_mbid = []
      artist_names = artist_connections_text.split("\n").map(&:strip)
      
      artist_names.each do |artist_name|
        lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
        lastfm_artist = lastfm.artist.get_info(artist: artist_name)
        
        if lastfm_artist['mbid'].blank?
          artist_names_without_mbid << lastfm_artist['name']
          
          next
        end
        
        artist_ids = MusicArtist.create_by_name(artist_name)
        
        next if artist_ids.none?
            
        artist_connection_artist_ids = artist_connections.where(artist_id: artist_ids).map(&:artist_id)
        artist_ids = artist_ids.select{|id| !artist_connection_artist_ids.include?(id) }
                
        if artist_ids.any?
          artist_ids.each do |artist_id|
            MusicMetadataEnrichment::GroupArtistConnection.create(group_id: id, artist_id: artist_id)
          end
        end
      end
      
      artist_names_without_mbid
    end
    
    def import_artists_of_group_members(options = {})
      last_page = options[:last_page]
      last_user_name_from_last_run = options[:last_user_name_from_last_run]
      library_start_page = options[:library_start_page]
      
      user_names, page, last_user_name, last_user_name_from_last_run_reached, i = [], nil, nil, false, 1
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      
      1000.times do |page|
        page +=1
        
        if last_page.present? && page == last_page
          i = (page * 50) + 1
        elsif last_page.present? && page < last_page
          next
        end
      
        puts "GROUP MEMBERS PAGE: #{page}"
        
        lastfm_users = MusicArtist.lastfm_request_class_method(lastfm, :group, :get_members, nil, group: 'Dark Electro', page: page)
        sleep 3
        
        if lastfm_users.select{|u| !user_names.include?(u['name'])}.none?
          # over last page
          break
        end
      
        lastfm_users.each do |lastfm_user|
          if user_names.include?(lastfm_user['name'])
            next
          else
            user_names << lastfm_user['name']
          end
      
          if lastfm_user['name'] == last_user_name_from_last_run
            last_user_name_from_last_run_reached = true
          elsif last_user_name_from_last_run.present? && !last_user_name_from_last_run_reached
            i += 1
            next
          end
          
          last_user_name = lastfm_user['name']
          puts "USER #{i}: #{last_user_name} (GROUP MEMBERS PAGE: #{page})"
          user = User.new
          user.group_page = page
          user.lastfm_user_name = lastfm_user['name']
      
          if lastfm_user['name'] == last_user_name_from_last_run && !library_start_page.nil?
            user.import_music_artists(lastfm, library_start_page)
          else
            user.import_music_artists(lastfm)
          end
          
          i += 1
        end
        
        [page, last_user_name]
      end
    end
    
    private
    
    def registered_on_lastfm
      return if name.blank?
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      
      begin
        lastfm.group.get_members(group: name)
      rescue Lastfm::ApiError
        errors[:name] << I18n.t('activerecord.errors.models.music_metadata_enrichment_group.attributes.name.not_registered_on_lastfm')
      end
    end
    
    def create_first_member
      memberships.create!(user_id: user_id)
    end
  end
end