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
        event.preventDefault()
        return false
        
    $(document.body).on "click", "#add_track_button", (event) ->
      event.preventDefault()
      
      artist_id = $('#year_in_review_music_track_artist_id').val()
      artist_id = if artist_id == null || artist_id == undefined || artist_id == '' then 0 else parseInt(artist_id)
      artist_name = $('#year_in_review_music_track_artist_name').val()
      artist_name = if artist_name == null || artist_name == undefined || artist_name == '' then '' else artist_name
      track_id = $('#year_in_review_music_track_track_id').val()
      track_id = if track_id == null || track_id == undefined || track_id == '' then 0 else parseInt(track_id)
      track_name = $('#year_in_review_music_track_track_name').val()
      track_name = if track_name == null || track_name == undefined || track_name == '' then '' else track_name
      
      if artist_id == 0 && artist_name == ''
        alert 'Please enter an artist name!'
        return
       
      if artist_id > 0 && track_name == ''
        alert 'Please enter a track name'
        return
         
      if artist_id == 0  
        $('#new_year_in_review_music_track').attr(
          'action', '/music/tracks/artist_confirmation?music_artist[name]=' + artist_name
        )
      else if track_id == 0
        $('#new_year_in_review_music_track').attr(
          'action', '/music/tracks/name_confirmation?music_track[name]=' + track_name + '&music_track[artist_id]=' + artist_id
        )
      
      $('#new_year_in_review_music_track').attr('method', 'get') if track_id == 0 
      $('#new_year_in_review_music_track').submit()