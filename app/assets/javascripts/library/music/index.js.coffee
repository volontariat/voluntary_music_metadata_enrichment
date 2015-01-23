$(document).ready ->
  $(document.body).on "change", "select[name^=\"year\"]", ->
    $.ajax(
      url: "/users/" + user_id + "/library/music/releases"
      data:
        year: $(this).val()
      type: "GET"
      dataType: "html"
    ).success (data) ->
      $("#releases").empty()
      $("#releases").append data
      return

  $(document.body).on "ajax:beforeSend", "#new_music_year_in_review_form", ->
    $("#years_in_review_spinner").show()
  
  $(document.body).on "ajax:complete", "#new_music_year_in_review_form", ->
    $("#years_in_review_spinner").hide()
    
  $(document.body).on "keyup.autocomplete", "#year_in_review_music_release_artist_name", ->  
    $(this).autocomplete
      source: $(this).data('source')
      minLength: 2
      appendTo: '#year_in_review_music_release_artist_name_suggestions'
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
        select: (event, ui) ->
          $(this).val(ui.item.value)
          $('#year_in_review_music_release_release_id').val(ui.item.id)
          
          return false;
    else
      alert 'Please select an artist!'
      event.preventDefault()
      return false
    
  $(document.body).on "click", ".year_in_review_music_release_link", (event) ->
    $this = $(this)
    
    $.ajax(url: $this.attr('href'), type: "GET", dataType: "html").success (data) ->
      $($this.data("replace")).html(data)
      window.make_year_in_review_music_releases_sortable()
      
    event.preventDefault()  
        
  first_position = $('#year_in_review_music_releases li:first').data('position')
  last_position = $('#year_in_review_music_releases li:last').data('position')
  
  window.make_year_in_review_music_releases_sortable = ->      
    $('#year_in_review_music_releases').sortable
      start: (event, ui) =>
        first_position = $('#year_in_review_music_releases li:first').data('position')
        last_position = $('#year_in_review_music_releases li:last').data('position')
        
      update: (event, ui) =>
        source_item = $(ui.item).closest('li')
        current_position = first_position
        previous_element = null
        
        $.each $('#year_in_review_music_releases li'), (index, element) ->
          $(element).data('position', current_position)  
          $('#year_in_review_music_release_position_' + $(element).data('id')).html(current_position)
          
          if $(element).data('id') == $(source_item).data('id')
            $.post '/users/current/library/music/year_in_review_music_releases/' + $(element).data('id') + '/move', { _method: 'put', position: current_position }
          
          previous_element = $(element)
          current_position += 1