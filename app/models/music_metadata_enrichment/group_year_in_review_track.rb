module MusicMetadataEnrichment
  class GroupYearInReviewTrack < ActiveRecord::Base
    include GroupYearInReviewMusicEntry
    include YearInReviewMusicTrackBase
    
    self.table_name = 'music_metadata_enrichment_group_year_in_review_tracks'
  end
end