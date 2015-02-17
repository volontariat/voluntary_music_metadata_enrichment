window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.NewView = class NewView
  constructor: ->
    $(document.body).on "keyup.autocomplete", "#year_in_review_music_release_artist_name", ->  
      $(this).autocomplete
        source: $(this).data('source')
        minLength: 2
        appendTo: '#year_in_review_music_release_artist_name_suggestions'
        search: (event, ui) ->
          $('#year_in_review_music_release_artist_id').val(null)
        select: (event, ui) ->
          $(this).val(ui.item.value)
          $('#year_in_review_music_release_artist_id').val(ui.item.id)
          
          return false;
  
    $(document.body).on "keyup.autocomplete", "#year_in_review_music_release_release_name", (event) ->  
      if $('#year_in_review_music_release_artist_id').val()
        $(this).autocomplete
          source: '/music/artists/' + $('#year_in_review_music_release_artist_id').val() + '/releases/autocomplete'
          minLength: 2
          appendTo: '#year_in_review_music_release_release_name_suggestions'
          search: (event, ui) ->
            $('#year_in_review_music_release_release_id').val(null)
          select: (event, ui) ->
            $(this).val(ui.item.value)
            $('#year_in_review_music_release_release_id').val(ui.item.id)
            
            return false;
      else
        event.preventDefault()
        return false
        
    $(document.body).on "click", "#add_release_button", (event) ->
      event.preventDefault()
      
      artist_id = $('#year_in_review_music_release_artist_id').val()
      artist_id = if artist_id == null || artist_id == undefined || artist_id == '' then 0 else parseInt(artist_id)
      artist_name = $('#year_in_review_music_release_artist_name').val()
      artist_name = if artist_name == null || artist_name == undefined || artist_name == '' then '' else artist_name
      release_id = $('#year_in_review_music_release_release_id').val()
      release_id = if release_id == null || release_id == undefined || release_id == '' then 0 else parseInt(release_id)
      release_name = $('#year_in_review_music_release_release_name').val()
      release_name = if release_name == null || release_name == undefined || release_name == '' then '' else release_name
      
      if artist_id == 0 && artist_name == ''
        alert 'Please enter an artist name!'
        return
      
      if artist_id > 0 && release_name == ''
        alert 'Please enter a release name'
        return
         
      if artist_id == 0  
        $('#new_year_in_review_music_release').attr(
          'action', '/music/releases/artist_confirmation?music_artist[name]=' + artist_name
        )
      else if release_id == 0
        $('#new_year_in_review_music_release').attr(
          'action', '/music/releases/name_confirmation?music_release[name]=' + release_name + '&music_release[artist_id]=' + artist_id
        )
      
      $('#new_year_in_review_music_release').attr('method', 'get') if release_id == 0  
      $('#new_year_in_review_music_release').submit()
