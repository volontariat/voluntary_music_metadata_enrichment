$(document).ready ->
  $("#music_video_status").change ->
    if $(this).val() is "Live"
      $("#live_music_video_attributes").show()
    else 
      $("#live_music_video_attributes").hide()