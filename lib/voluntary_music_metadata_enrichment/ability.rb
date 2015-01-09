module VoluntaryMusicMetadataEnrichment
  class Ability
    def self.after_initialize
      Proc.new do |ability, user, options|
        ability.can :read, [
          MusicArtist, MusicRelease, MusicTrack, MusicVideo
        ]
        
        if user.present?
          ability.can(:create, MusicArtist)
        end
      end
    end
  end
end
