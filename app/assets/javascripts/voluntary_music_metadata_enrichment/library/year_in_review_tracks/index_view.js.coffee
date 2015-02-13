window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView = class IndexView
  constructor: ->
    window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.makeCollectionSortable()
    
    $(document.body).on "click", ".play_track_button", (event) ->
      event.preventDefault()
      $('#bootstrap_modal').html(
        '<div class="modal-header">' +
        '<button type="button" id="close_bootstrap_modal_button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>' +
        '<h3>Play Track</h3>' +
        '</div>' +
        '<div class="modal-body" style="overflow-y:none;">' +
        '<iframe src="https://embed.spotify.com/?uri=spotify:track:' + $(this).data('spotify-track-id') + '&view=coverart" frameborder="0" allowtransparency="true" width="300" height="80"></iframe>' +
        '</div>' +
        '<div class="modal-footer">' +
        '</div>'
      )  
      $('#bootstrap_modal').modal('show')
    
    $(document.body).on "ajax:beforeSend", ".destroy_music_year_in_review_top_track_link", ->
      $(this).find('.ajax_spinner').show()
    
    $(document.body).on "ajax:beforeSend", ".create_music_year_in_review_flop_track_link", ->
      $(this).find('.ajax_spinner').show()
    
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