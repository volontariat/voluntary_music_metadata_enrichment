module Library
  module Music
    module YearInReviewTracksHelper
      def year_in_review_track_links(year_in_review_tracks)
        year_in_review_tracks.map{|t| "#{t.position}. " + link_to(t.track_name, music_track_path(t.track_id)) }.join(', ')
      end
      
      def year_in_review_top_track_positions_sum(year_in_review_tracks)
        year_in_review_tracks.sum{|t| @year_in_review_tracks_count - t.position + 1 }
      end
    end
  end
end