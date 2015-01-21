# -*- encoding : utf-8 -*-
class MusicLibraryArtist < ActiveRecord::Base
  belongs_to :user
  belongs_to :artist, class_name: 'MusicArtist'
  
  validates :user_id, presence: true
  validates :artist_id, presence: true, uniqueness: { scope: :user_id }
  
  attr_accessible :user_id, :artist_id, :plays
  
  after_create :create_music_track_matches
  
  private
  
  def create_music_track_matches
    return unless artist.active?
    
    artist.tracks.where('master_track_id IS NULL').find_each do |track|
      user.create_music_track_matches_for_one_track(track)
    end
  end
end