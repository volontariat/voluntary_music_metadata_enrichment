window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView = class IndexView
  constructor: ->
    window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.makeCollectionSortable()
    
    $(document.body).on "click", ".play_track_button", (event) ->
      target = null
      
      if $(this).data('target') == undefined
        target = '#bootstrap_modal'
      else
        target = $(this).data('target')
        
      event.preventDefault()
      
      iframe = '<iframe src="https://embed.spotify.com/?uri=spotify:track:' + $(this).data('spotify-track-id') + '&view=coverart" frameborder="0" allowtransparency="true" width="300" height="80"></iframe>'
      
      if target == '#bootstrap_modal'
        $(target).html(
          '<div class="modal-header">' +
          '<button type="button" id="close_bootstrap_modal_button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>' +
          '<h3>Play Track</h3>' +
          '</div>' +
          '<div class="modal-body" style="overflow-y:none;">' +
          iframe +
          '</div>' +
          '<div class="modal-footer">' +
          '</div>'
        )  
        $(target).modal('show')
      else
        $(target).html(iframe)
    
    $(document.body).on "ajax:beforeSend", ".destroy_music_year_in_review_top_track_link", ->
      $(this).find('.ajax_spinner').show()
    
    $(document.body).on "ajax:beforeSend", ".create_music_year_in_review_flop_track_link", ->
      $(this).find('.ajax_spinner').show()
    
    new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.NewView()
    
    $('#competitive_list_for_tracks').competitiveList
      competitor_name_proc: (csv) ->
        return '<iframe src="https://embed.spotify.com/?uri=spotify:track:' + csv.split(';')[0] + '&view=coverart" frameborder="0" allowtransparency="true" width="300" height="80"></iframe><br/>' + $("#competitor_#{csv.split(';')[1]}").find('.competitor_name').html()
   
  @makeCollectionSortable: ->
    $('#year_in_review_music_tracks').multisortable
      start: (event, ui) =>
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.showSpinnerForSelectedCompetitors()
        
      update: (event, ui) =>
        $('#year_in_review_music_tracks').sortable('disable')
        setTimeout (->
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.putPositions(ui.item.data('id'))
          return
        ), 1000
  
  @showSpinnerForSelectedCompetitors: ->
    $.each $('#year_in_review_music_tracks li.selected'), (index, element) ->
      $(element).find('.sorting_spinner').show()

  @hideSpinnerForSelectedCompetitors: ->
    $.each $('#year_in_review_music_tracks li.selected'), (index, element) ->
      $(element).find('.sorting_spinner').hide()
        
  @putPositions: (competitorId) ->
    newPositionOfCompetitor = null
    
    unless window.matches.length > 0 && $('#year_in_review_music_tracks li.selected').length > 1
      newPositionOfCompetitor = window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.resetPositions(competitorId)
    
    if window.matches.length == 0
      positions = {}
        
      $.each $('#year_in_review_music_tracks li.selected'), (index, element) ->
        positions[$(element).data('position')] = $(element).data('id')
        
      $.post('/users/current/library/music/year_in_review_music_tracks/move', { _method: 'put', positions: positions }).always(=>
        $('#year_in_review_music_tracks').sortable('enable')
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.hideSpinnerForSelectedCompetitors()
      )
    else
      if $('#year_in_review_music_tracks li.selected').length == 1
        $('#competitive_list_for_tracks').competitiveList 'moveCompetitorToPosition', competitorId, newPositionOfCompetitor, => 
          $('#year_in_review_music_tracks').sortable('enable')
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.hideSpinnerForSelectedCompetitors()
      else
        alert 'Dragging of multiple elements is not supported in round-robin tournament mode!'
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.cancelSorting()
        $('#year_in_review_music_tracks').sortable('enable')
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.hideSpinnerForSelectedCompetitors()
   
  @cancelSorting: ->
    $wrapper = $('#year_in_review_music_tracks')

    $wrapper.find('li').sort((a, b) ->
      +parseInt($(a).data('position')) - +parseInt($(b).data('position'))
    ).appendTo $wrapper 
   
  @resetPositions: (competitorId) ->
    position = null
    current_position = 1
    
    $.each $('#year_in_review_music_tracks li'), (index, element) ->
      $(element).data('position', current_position)  
      $(element).find('.competitor_position').html(current_position)
      position = current_position if $(element).data('id') == competitorId
      current_position += 1
     
    return position