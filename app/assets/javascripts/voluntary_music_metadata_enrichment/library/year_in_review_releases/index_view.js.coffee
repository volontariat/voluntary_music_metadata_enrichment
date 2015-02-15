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
    new window.Voluntary.DomManipulation.CompetitiveList()
    
  @makeCollectionSortable: ->
    $('#year_in_review_music_releases').multisortable
      start: (event, ui) =>
        window.first_position = $('#year_in_review_music_releases li:first').data('position')
        window.last_position = $('#year_in_review_music_releases li:last').data('position')
        
      update: (event, ui) =>
        setTimeout window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.sortByPosition, 1000
        
  @sortByPosition: ->
    current_position = window.first_position
    releases_count = $.each $('#year_in_review_music_releases li').length
    
    $.each $('#year_in_review_music_releases li'), (index, element) ->
      $(element).data('position', current_position)  
      $(element).find('.competitorPosition').html(current_position)
      current_position += 1
      
    positions = {}
      
    $.each $('#year_in_review_music_releases li.selected'), (index, element) ->
      positions[$(element).data('position')] = $(element).data('id')
      
    $.post '/users/current/library/music/year_in_review_music_releases/move', { _method: 'put', positions: positions }  