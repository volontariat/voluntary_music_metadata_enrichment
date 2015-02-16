# -*- encoding : utf-8 -*-
class MusicArtist < ActiveRecord::Base
  include LastfmRequest
  
  has_many :releases, class_name: 'MusicRelease', foreign_key: 'artist_id', dependent: :destroy
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'artist_id'
  has_many :videos, class_name: 'MusicVideo', foreign_key: 'artist_id'
  has_many :music_library_artists, dependent: :destroy, foreign_key: 'artist_id'
  
  scope :name_like, ->(name) do
    where(MusicArtist.arel_table[:name].matches("%#{name}%"))
  end
  
  validates :name, presence: true
  validates :mbid, presence: true, uniqueness: true, length: { is: 36 }
  
  after_update :synchronize_artist_name
  after_create :create_bonustracks_release
  
  attr_accessible :name, :is_ambiguous, :mbid, :disambiguation, :founded_at, :dissolved_at, :listeners, :plays
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |artist, transition|
      musicbrainz_artist = MusicBrainz::Artist.find(artist.mbid)
      is_ambiguous = if artist.is_ambiguous.nil?
        MusicBrainz::Artist.search(artist.name).select{|a| a[:name].downcase == artist.name.downcase}.length > 1
      else
        artist.is_ambiguous
      end
      
      artist.update_attributes(
        disambiguation: musicbrainz_artist.disambiguation,
        founded_at: artist.musicbrainz_date_to_iso_date(musicbrainz_artist.begin), 
        dissolved_at: artist.musicbrainz_date_to_iso_date(musicbrainz_artist.end),
        is_ambiguous: is_ambiguous
      )
      
      unless artist.listeners.present? && artist.plays.present?
        lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
        lastfm_artist = artist.lastfm_request(lastfm, :artist, :get_info, 'The artist you supplied could not be found', artist: artist.name)
        artist.update_attributes(listeners: lastfm_artist['stats']['listeners'], plays: lastfm_artist['stats']['playcount']) unless lastfm_artist.nil?
      end
       
      unless artist.is_classical?(lastfm)
        artist.import_releases(musicbrainz_artist)
        #artist.import_bonus_tracks
        #artist.import_music_videos_from_tapetv
      end
    end
  end
  
  def is_classical?(lastfm = nil)
    lastfm ||= Lastfm.new(LastfmApiKey, LastfmApiSecret)
    
    begin
      lastfm_artist_tags = lastfm_request(
        lastfm, :artist, :get_top_tags, 'The artist you supplied could not be found', artist: name, raise_if_response_is_just_nil: true
      )
        
      if lastfm_artist_tags.nil?
        raise 'lastfm failed: ' + [:artist, :get_top_tags, 'The artist you supplied could not be found', { artist: name }].inspect
      end
      
      tags = lastfm_artist_tags.map{|t| t['name'].downcase }[0..9] rescue []
      tags.select{|t| ['classic', 'classical'].include?(t) }.any? && tags.select{|t| ['pop', 'rock', 'crossover', 'alternative'].include?(t) }.none?
    rescue StandardError => e
      if e.message.match('last.fm response is just nil without exceptions')
        false
      else
        raise e
      end 
    end
  end
  
  def import_releases(musicbrainz_artist = nil)
    musicbrainz_artist = MusicBrainz::Artist.find(mbid) unless musicbrainz_artist
    
    offset, count = 0, 100
      
    begin
      release_groups = musicbrainz_artist.release_groups(offset: offset)
      count = release_groups.total_count
      release_groups = release_groups.select{|r| ['Album', 'Soundtrack', 'EP'].include?(r.type) && r.secondary_types.select{|st| MusicRelease::SECONDARY_TYPES_BLACKLIST.include?(st)}.none? && r.artists.length == 1}
      
      voluntary_releases = if release_groups.none?
        []
      else 
        releases.where('music_releases.name IN (?)', release_groups.map(&:title).uniq).map{|r| "#{(r.is_lp ? 1 : 0)};#{r.name}"}
      end
      
      release_groups.select{|r| !voluntary_releases.include?("#{r.type == 'Album' ? 1 : 0};#{r.title}")}.each do |musicbrainz_release_group|
        release_is_lp_plus_name = "#{musicbrainz_release_group.type == 'Album' ? 1 : 0};#{musicbrainz_release_group.title}"
        
        next if voluntary_releases.include?(release_is_lp_plus_name)
        
        musicbrainz_releases = musicbrainz_release_group.releases
        
        next if musicbrainz_releases.select{|r| r.status == 'Official' && (r.media.map(&:format).none? || r.media.map(&:format).select{|f| !['DVD-Video', 'DVD'].include?(f) }.any?) }.none?
        
        release = releases.create(
          artist_name: name, name: musicbrainz_release_group.title,
          is_lp: musicbrainz_release_group.type == 'Album'
        )
        
        next unless release.persisted?
          
        release.releases = musicbrainz_releases
        release.import_metadata!
        voluntary_releases << release_is_lp_plus_name
      end
      
      offset += 100
    end while offset < count  
  end
  
  def import_bonus_tracks
    offset = 0
    count = 100
    bonus_track_names = []
    
    begin
      recordings = MusicBrainz::Recording.search(mbid, nil, limit: 100, offset: offset, create_models: true)
      count = recordings.total_count
      recordings = recordings.select{|r| !MusicTrack.name_included_in_bonustrack_blacklist?(r.title) && r.disambiguation.blank? }
      recording_titles = recordings.map{|r| MusicTrack.format_name(r.title).downcase }.uniq
      voluntary_names = MusicTrack.where("artist_id = :artist_id AND LOWER(name) IN(:name)", artist_id: id, name: recording_titles).map{|t| t.name.downcase }
      
      recordings.select{|r| !voluntary_names.include?(MusicTrack.format_name(r.title).downcase) }.each do |recording|
        next if bonus_track_names.include? MusicTrack.format_name(recording.title).downcase
        
        track = MusicTrack.new(artist: self, name: MusicTrack.format_name(recording.title))
        track.artist_mbid = mbid
        
        if track.is_bonus_track?
          track.create_bonus_track(recording.id)
          bonus_track_names << track.name.downcase
        end
      end
      
      offset += 100
    end while offset < count
  end
  
  def import_music_videos_from_tapetv
    tapetv_videos, page = [], 1
    
    begin
      response = nil
      
      begin
        response = JSON.parse(HTTParty.get("http://www.tape.tv/#{name.split(' ').join('-').downcase}/videos.json?page=#{page}&page_size=8").body)
      rescue JSON::ParserError
      end
      
      break if response.nil?
      
      tapetv_videos += response.select{|v| !v['title'].match(/\(/) && !v['title'].match(/live/i) }.map{|v| { name: v['title'].gsub(/\(Video\)/, '').strip, url: v['share_url'] } }
      sleep 5
      
      break if response.length != 8
      
      page += 1
    end while !response.nil? && response.length > 0
    
    return if tapetv_videos.empty?
    
    tracks.where('LOWER(name) IN(?)', tapetv_videos.map{|v| MusicTrack.format_name(v[:name]).downcase }).each do |track|
      tapetv_video = tapetv_videos.select do |v| 
        MusicTrack.format_name(v[:name]).downcase == track.name.downcase ||
        MusicTrack.format_name(v[:name]).downcase.gsub('ß', 'ss') == track.name.downcase.gsub('ß', 'ss')
      end.first
      
      MusicVideo.create(status: 'Official', track_id: track.id, url: tapetv_video[:url]) unless tapetv_video.nil?
    end
  end
  
  def bonus_tracks_release
    releases.where(name: '[Bonus Tracks]').first
  end
  
  def musicbrainz_date_to_iso_date(date)
    return date if date.blank?
    
    splitted_date = date.split('-')
    
    if splitted_date.length == 1
      "#{splitted_date.first}-01-01"
    elsif splitted_date.length == 2
      "#{splitted_date.first}-#{splitted_date.last}-01"
    else
      date
    end
  end
  
  private
  
  def create_bonustracks_release
    release = releases.create(name: '[Bonus Tracks]', is_lp: true)
    release.update_attribute(:state, 'active')
  end
  
  def synchronize_artist_name
    return unless name_changed?
    
    [MusicRelease, MusicTrack, MusicVideo].each do |klass|
      klass.where('artist_id = ?', id).update_all ['artist_name = ?', name]
    end
  end
end