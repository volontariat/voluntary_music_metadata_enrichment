# -*- encoding : utf-8 -*-
class MusicLibraryArtist < ActiveRecord::Base
  belongs_to :user
  belongs_to :artist, class_name: 'MusicArtist'
  
  validates :user_id, presence: true
  validates :artist_id, presence: true, uniqueness: { scope: :user_id }
  
  attr_accessible :user_id, :artist_id, :plays
end