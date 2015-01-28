window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView = class IndexView
  constructor: ->
    window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.makeCollectionSortable()
    new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.NewView()
    
  @makeCollectionSortable: ->
    $('#year_in_review_music_tracks').sortable
      start: (event, ui) =>
        window.first_position = $('#year_in_review_music_tracks li:first').data('position')
        window.last_position = $('#year_in_review_music_tracks li:last').data('position')
        
      update: (event, ui) =>
        source_item = $(ui.item).closest('li')
        current_position = window.first_position
        previous_element = null
        
        $.each $('#year_in_review_music_tracks li'), (index, element) ->
          $(element).data('position', current_position)  
          $('#year_in_review_music_track_position_' + $(element).data('id')).html(current_position)
          
          if $(element).data('id') == $(source_item).data('id')
            $.post '/users/current/library/music/year_in_review_music_tracks/' + $(element).data('id') + '/move', { _method: 'put', position: current_position }
          
          previous_element = $(element)
          current_position += 1