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
    
    new window.Voluntary.DomManipulation.CompetitiveList competitor_name_proc: (csv) ->
      if csv == null
        return 'CSV is null'
      else if csv == undefined
        return 'CSV is undefined'
      else
        return '<iframe src="https://embed.spotify.com/?uri=spotify:album:' + csv.split(';')[0] + '" frameborder="0" allowtransparency="true" width="300" height="380"></iframe><br/>' + $("#competitor_#{csv.split(';')[1]}").find('.competitor_name').html()
    
  @makeCollectionSortable: ->
    $('#year_in_review_music_releases').multisortable
      update: (event, ui) =>
        $('#year_in_review_music_releases').sortable('disable');
        setTimeout window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.putPositions, 1000
          
  @putPositions: ->
    window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.resetPositions()
    positions = {}
      
    $.each $('#year_in_review_music_releases li.selected'), (index, element) ->
      positions[$(element).data('position')] = $(element).data('id')
      
    $.post('/users/current/library/music/year_in_review_music_releases/move', { _method: 'put', positions: positions }).always(=>
      $('#year_in_review_music_releases').sortable('enable');
    )  
   
  @resetPositions: ->
    current_position = 1
    
    $.each $('#year_in_review_music_releases li'), (index, element) ->
      $(element).data('position', current_position)  
      $(element).find('.competitorPosition').html(current_position)
      current_position += 1