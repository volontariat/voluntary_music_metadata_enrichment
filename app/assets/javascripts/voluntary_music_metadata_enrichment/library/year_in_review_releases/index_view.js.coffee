window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView = class IndexView
  constructor: ->
    window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.makeCollectionSortable()
    
    $(document.body).on "ajax:beforeSend", ".destroy_music_year_in_review_top_release_link", ->
      $(this).find('.ajax_spinner').show()
    
    $(document.body).on "ajax:beforeSend", ".create_music_year_in_review_flop_release_link", ->
      $(this).find('.ajax_spinner').show()
    
    new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.NewView()
    
  @makeCollectionSortable: ->
    $('#year_in_review_music_releases').sortable
      start: (event, ui) =>
        window.first_position = $('#year_in_review_music_releases li:first').data('position')
        window.last_position = $('#year_in_review_music_releases li:last').data('position')
        
      update: (event, ui) =>
        source_item = $(ui.item).closest('li')
        current_position = window.first_position
        previous_element = null
        
        $.each $('#year_in_review_music_releases li'), (index, element) ->
          $(element).data('position', current_position)  
          $('#year_in_review_music_release_position_' + $(element).data('id')).html(current_position)
          
          if $(element).data('id') == $(source_item).data('id')
            $.post '/users/current/library/music/year_in_review_music_releases/' + $(element).data('id') + '/move', { _method: 'put', position: current_position }
          
          previous_element = $(element)
          current_position += 1