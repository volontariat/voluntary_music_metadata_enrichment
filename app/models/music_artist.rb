# -*- encoding : utf-8 -*-
class MusicArtist < ActiveRecord::Base
  has_many :releases, class_name: 'MusicRelease', foreign_key: 'artist_id', dependent: :destroy
  has_many :tracks, class_name: 'MusicTrack', foreign_key: 'artist_id'
  has_many :videos, class_name: 'MusicVideo', foreign_key: 'artist_id'
  
  scope :name_like, ->(name) do
    where(MusicArtist.arel_table[:name].matches("%#{name}%"))
  end
  
  validates :name, presence: true
  validates :mbid, presence: true, uniqueness: true, length: { is: 36 }
  
  after_update :synchronize_artist_name
  after_create :create_bonustracks_release
  
  attr_accessible :name, :mbid, :disambiguation, :founded_at, :dissolved_at, :listeners, :plays
  
  state_machine :state, initial: :without_metadata do
    event :import_metadata do transition :without_metadata => :active; end
    
    before_transition :without_metadata => :active do |artist, transition|
      musicbrainz_artist = MusicBrainz::Artist.find(artist.mbid)
  
      artist.update_attributes(
        disambiguation: musicbrainz_artist.disambiguation,
        founded_at: artist.musicbrainz_date_to_iso_date(musicbrainz_artist.begin), 
        dissolved_at: artist.musicbrainz_date_to_iso_date(musicbrainz_artist.end)
      )
      
      lastfm = Lastfm.new(LastfmApiKey, LastfmApiSecret)
      lastfm_artist = lastfm.artist.get_info(mbid: artist.mbid)
      artist.update_attributes(listeners: lastfm_artist['stats']['listeners'], plays: lastfm_artist['stats']['playcount'])
      
      offset, count = 0, 100
      
      begin
        release_groups = musicbrainz_artist.release_groups(offset: offset)
        count = release_groups.total_count
        
        release_groups.select{|r| ['Album', 'EP'].include?(r.type) && r.secondary_types.select{|st| ['Audiobook', 'Compilation', 'Live', 'Remix'].include?(st)}.none? && r.artists.length == 1}.each do |musicbrainz_release_group|
          releases = musicbrainz_release_group.releases
          
          next if releases.select{|r| r.status == 'Official' && (r.media.map(&:format).none? || r.media.map(&:format).select{|f| !['DVD-Video', 'DVD'].include?(f) }.any?) }.none?
          
          release = MusicRelease.create(artist_id: artist.id, artist_name: artist.name, name: musicbrainz_release_group.title)
          
          next unless release.persisted?
            
          release.releases = releases
          release.import_metadata!
        end
        
        offset += 100
      end while offset < count  
      
      #artist.import_bonus_tracks
      #artist.import_music_videos_from_tapetv
    end
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
    release = releases.create(name: '[Bonus Tracks]')
    release.update_attribute(:state, 'active')
  end
  
  def synchronize_artist_name
    return unless name_changed?
    
    [MusicRelease, MusicTrack, MusicVideo].each do |klass|
      klass.where('artist_id = ?', id).update_all ['artist_name = ?', name]
    end
  end
end