module VoluntaryMusicMetadataEnrichment
  class Ability
    def self.after_initialize
      Proc.new do |ability, user, options|
        ability.can :read, [
          MusicMetadataEnrichment::Group, MusicMetadataEnrichment::GroupArtistConnection, YearInReviewMusic, YearInReviewMusicRelease, YearInReviewMusicTrack, MusicArtist, MusicRelease, MusicTrack, MusicVideo
        ]
        
        if user.present?
          ability.can(:create, MusicLibraryArtist)
          ability.can(:destroy, MusicLibraryArtist) {|music_library_artist| music_library_artist.user_id == user.id }
          ability.can(:create, MusicMetadataEnrichment::Group)
          ability.can([:create, :name_confirmation, :select_artist, :creation], MusicMetadataEnrichment::GroupArtistConnection)
          ability.can(:create, YearInReviewMusic)
          ability.can([:create, :move, :destroy], YearInReviewMusicRelease) {|year_in_review_music_release| year_in_review_music_release.year_in_review_music.user_id == user.id }
          ability.can(:multiple_new, YearInReviewMusicRelease)
          ability.can([:create, :move, :destroy], YearInReviewMusicTrack) {|year_in_review_music_track| year_in_review_music_track.year_in_review_music.user_id == user.id }
          ability.can(:multiple_new, YearInReviewMusicTrack)
          ability.can([:create, :name_confirmation], MusicArtist)
          ability.can([:create, :artist_confirmation, :select_artist, :name, :name_confirmation, :announce, :create_announcement], MusicRelease)
          ability.can([:create, :artist_confirmation, :select_artist, :name, :name_confirmation], MusicTrack)
          ability.can([:create, :artist_confirmation, :select_artist, :track_name, :track_confirmation, :create_track, :metadata], MusicVideo)
        end
      end
    end
  end
end
