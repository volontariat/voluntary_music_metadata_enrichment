module MusicMetadataEnrichment
  class GroupYearInReviewRelease < ActiveRecord::Base
    include GroupYearInReviewMusicEntry
    include YearInReviewMusicReleaseBase
    
    self.table_name = 'music_metadata_enrichment_group_year_in_review_releases'    
  end
end