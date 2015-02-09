# -*- encoding : utf-8 -*-
module MusicMetadataEnrichment
  module LastfmHelper
    def lastfm_track_text(track, options = {})
      short = options.has_key?(:short) ? options[:short] : false
      
      artist, name = if track.is_a? MusicTrack
        [track.artist_name, track.name]
      elsif track.is_a? YearInReviewMusicTrack
        [track.artist_name, track.track_name]
      end
      
      text = []
      text << "[artist]#{artist}[/artist]" unless short
      text << "[track artist=#{artist}]#{name}[/track]"
      text.join(' – ')
    end
  end
end