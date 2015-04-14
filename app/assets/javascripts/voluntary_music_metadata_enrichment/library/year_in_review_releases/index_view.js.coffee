window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView = class IndexView
  constructor: ->
    window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.makeCollectionSortable()
    
    $(document.body).on "click", ".play_album_button", (event) ->
      target = null
      
      if $(this).data('target') == undefined
        target = '#bootstrap_modal'
      else
        target = $(this).data('target')
        
      event.preventDefault()
      
      iframe = '<iframe src="https://embed.spotify.com/?uri=spotify:album:' + $(this).data('spotify-album-id') + '" frameborder="0" allowtransparency="true" width="300" height="380"></iframe>'
    
      if target == '#bootstrap_modal'
        $(target).html(
          '<div class="modal-header">' +
          '<button type="button" id="close_bootstrap_modal_button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>' +
          '<h3>Play Album</h3>' +
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
    
    $(document.body).on "ajax:beforeSend", ".destroy_music_year_in_review_top_release_link", ->
      $(this).find('.ajax_spinner').show()
    
    $(document.body).on "ajax:beforeSend", ".create_music_year_in_review_flop_release_link", ->
      $(this).find('.ajax_spinner').show()
    
    new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.NewView()
    
    $('#competitive_list_for_releases').competitiveList
      competitor_name_proc: (csv) ->
        return '<iframe src="https://embed.spotify.com/?uri=spotify:album:' + csv.split(';')[0] + '" frameborder="0" allowtransparency="true" width="300" height="380"></iframe><br/>' + $("#competitor_#{csv.split(';')[1]}").find('.competitor_name').html()
        
  @makeCollectionSortable: ->
    $('#year_in_review_music_releases').multisortable
      start: (event, ui) =>
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.showSpinnerForSelectedCompetitors()
        
      update: (event, ui) =>
        $('#year_in_review_music_releases').sortable('disable')
        setTimeout (->
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.putPositions(ui.item.data('id'))
          return
        ), 1000
  
  @showSpinnerForSelectedCompetitors: ->
    $.each $('#year_in_review_music_releases li.selected'), (index, element) ->
      $(element).find('.sorting_spinner').show()

  @hideSpinnerForSelectedCompetitors: ->
    $.each $('#year_in_review_music_releases li.selected'), (index, element) ->
      $(element).find('.sorting_spinner').hide()
        
  @putPositions: (competitorId) ->
    newPositionOfCompetitor = null
    
    unless $('#competitive_list_for_releases').data('competitiveList').matches.length > 0 && $('#year_in_review_music_releases li.selected').length > 1
      newPositionOfCompetitor = window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.resetPositions(competitorId)
    
    if $('#competitive_list_for_releases').data('competitiveList').matches.length == 0
      positions = {}
        
      $.each $('#year_in_review_music_releases li.selected'), (index, element) ->
        positions[$(element).data('position')] = $(element).data('id')
        
      $.post('/users/current/library/music/year_in_review_music_releases/move', { _method: 'put', positions: positions }).always(=>
        $('#year_in_review_music_releases').sortable('enable')
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.hideSpinnerForSelectedCompetitors()
      )  
    else
      if $('#year_in_review_music_releases li.selected').length == 1
        $('#competitive_list_for_releases').competitiveList 'moveCompetitorToPosition', competitorId, newPositionOfCompetitor, =>
          $('#year_in_review_music_releases').sortable('enable')
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.hideSpinnerForSelectedCompetitors()
      else
        alert 'Dragging of multiple elements is not supported in round-robin tournament mode!'
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.cancelSorting()
        $('#year_in_review_music_releases').sortable('enable')
        window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.hideSpinnerForSelectedCompetitors()
        
  @cancelSorting: ->
    $wrapper = $('#year_in_review_music_releases')

    $wrapper.find('li').sort((a, b) ->
      +parseInt($(a).data('position')) - +parseInt($(b).data('position'))
    ).appendTo $wrapper  
   
  @resetPositions: (competitorId) ->
    position = null
    current_position = 1
    
    $.each $('#year_in_review_music_releases li'), (index, element) ->
      $(element).data('position', current_position)  
      $(element).find('.competitor_position').html(current_position)
      position = current_position if $(element).data('id') == competitorId
      current_position += 1
      
    return position 