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
    new window.Voluntary.DomManipulation.CompetitiveList()
    
  @makeCollectionSortable: ->
    $('#year_in_review_music_tracks').multisortable
      start: (event, ui) =>
        window.first_position = $('#year_in_review_music_tracks li:first').data('position')
        window.last_position = $('#year_in_review_music_tracks li:last').data('position')
          
      update: (event, ui) =>
        setTimeout window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.sortByPosition, 1000
        
  @sortByPosition: ->
    current_position = window.first_position
    tracks_count = $.each $('#year_in_review_music_tracks li').length
    
    $.each $('#year_in_review_music_tracks li'), (index, element) ->
      $(element).data('position', current_position)  
      $(element).find('.competitorPosition').html(current_position)
      current_position += 1
      
    positions = {}
      
    $.each $('#year_in_review_music_tracks li.selected'), (index, element) ->
      positions[$(element).data('position')] = $(element).data('id')
      
    $.post '/users/current/library/music/year_in_review_music_tracks/move', { _method: 'put', positions: positions }  
