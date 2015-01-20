module VoluntaryMusicMetadataEnrichment
  class Ability
    def self.after_initialize
      Proc.new do |ability, user, options|
        ability.can :read, [
          MusicMetadataEnrichment::Group, MusicMetadataEnrichment::GroupArtistConnection, MusicArtist, MusicRelease, MusicTrack, MusicVideo
        ]
        
        if user.present?
          ability.can(:create, MusicMetadataEnrichment::Group)
          ability.can([:create, :name_confirmation, :select_artist, :creation], MusicMetadataEnrichment::GroupArtistConnection)
          ability.can([:create, :name_confirmation], MusicArtist)
          ability.can([:create, :artist_confirmation, :select_artist, :name, :name_confirmation, :announce, :create_announcement], MusicRelease)
          ability.can([:create, :artist_confirmation, :select_artist, :name, :name_confirmation], MusicTrack)
          ability.can([:create, :artist_confirmation, :select_artist, :track_name, :track_confirmation, :create_track, :metadata], MusicVideo)
        end
      end
    end
  end
end
