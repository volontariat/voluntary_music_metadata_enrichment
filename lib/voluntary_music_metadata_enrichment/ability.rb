module VoluntaryMusicMetadataEnrichment
  class Ability
    def self.after_initialize
      Proc.new do |ability, user, options|
        ability.can :read, [
          MusicMetadataEnrichment::Group, MusicMetadataEnrichment::GroupArtistConnection, MusicMetadataEnrichment::GroupMembership,
          MusicMetadataEnrichment::GroupYearInReview, MusicMetadataEnrichment::GroupYearInReviewRelease,
          MusicMetadataEnrichment::GroupYearInReviewTrack,
          YearInReviewMusic, YearInReviewMusicRelease, YearInReviewMusicReleaseFlop, YearInReviewMusicTrack, YearInReviewMusicTrackFlop, 
          MusicArtist, MusicRelease, MusicTrack, MusicVideo
        ]
        
        if user.present?
          ability.can(:create, MusicLibraryArtist)
          ability.can(:destroy, MusicLibraryArtist) {|music_library_artist| music_library_artist.user_id == user.id }
          ability.can(:create, MusicMetadataEnrichment::Group)
          ability.can([:create, :name_confirmation, :select_artist, :creation], MusicMetadataEnrichment::GroupArtistConnection)
          ability.can(:create, MusicMetadataEnrichment::GroupMembership)
          ability.can(:restful_actions, MusicMetadataEnrichment::GroupMembership) {|membership| membership.user_id == user.id }
          ability.can(:create, YearInReviewMusic)
          ability.can([:destroy, :publish], YearInReviewMusic) {|y| y.user_id == user.id }
          ability.can([:create, :move, :destroy, :update_all_positions], YearInReviewMusicRelease) {|r| r.year_in_review_music.user_id == user.id }
          ability.can([:multiple_new, :export], YearInReviewMusicRelease)
          ability.can([:create], YearInReviewMusicReleaseFlop) {|r| r.year_in_review_music.user_id == user.id }
          ability.can([:create, :move, :destroy, :update_all_positions], YearInReviewMusicTrack) {|year_in_review_music_track| year_in_review_music_track.year_in_review_music.user_id == user.id }
          ability.can([:multiple_new, :export], YearInReviewMusicTrack)
          ability.can([:create], YearInReviewMusicTrackFlop) {|t| t.year_in_review_music.user_id == user.id }
          ability.can([:create, :name_confirmation], MusicArtist)
          ability.can([:create, :artist_confirmation, :select_artist, :name, :name_confirmation, :announce, :create_announcement], MusicRelease)
          ability.can([:create, :artist_confirmation, :select_artist, :name, :name_confirmation], MusicTrack)
          ability.can([:create, :artist_confirmation, :select_artist, :track_name, :track_confirmation, :create_track, :metadata], MusicVideo)
        end
      end
    end
  end
end
