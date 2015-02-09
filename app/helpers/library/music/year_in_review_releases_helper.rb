module Library
  module Music
    module YearInReviewReleasesHelper
      def year_in_review_release_top_track_lastfm_links(year_in_review_tracks)
        if year_in_review_tracks.any?
          "(#{year_in_review_top_track_positions_sum(year_in_review_tracks)}: " + 
          year_in_review_tracks.map{|t| "#{t.position}. #{lastfm_track_text(t, short: true)}" }.join(', ') + ')'
        else
          ''
        end
      end
    end
  end
end