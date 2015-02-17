window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.NewView = class NewView
  constructor: ->
    $(document.body).on "keyup.autocomplete", "#year_in_review_music_track_artist_name", ->  
      $(this).autocomplete
        source: $(this).data('source')
        minLength: 2
        appendTo: '#year_in_review_music_track_artist_name_suggestions'
        search: (event, ui) ->
          $('#year_in_review_music_track_artist_id').val(null)
        select: (event, ui) ->
          $(this).val(ui.item.value)
          $('#year_in_review_music_track_artist_id').val(ui.item.id)
          
          return false;
  
    $(document.body).on "keyup.autocomplete", "#year_in_review_music_track_track_name", (event) ->  
      if $('#year_in_review_music_track_artist_id').val()
        $(this).autocomplete
          source: '/music/artists/' + $('#year_in_review_music_track_artist_id').val() + '/tracks/autocomplete'
          minLength: 2
          appendTo: '#year_in_review_music_track_track_name_suggestions'
          search: (event, ui) ->
            $('#year_in_review_music_track_track_id').val(null)
          select: (event, ui) ->
            $(this).val(ui.item.value)
            $('#year_in_review_music_track_track_id').val(ui.item.id)
            
            return false;
      else
        alert 'Please select an artist!'
        event.preventDefault()
        return false