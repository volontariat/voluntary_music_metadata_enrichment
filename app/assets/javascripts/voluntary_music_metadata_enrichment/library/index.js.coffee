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

  $(document.body).on "ajax:beforeSend", ".destroy_music_library_artist_link", ->
    $(this).find('.ajax_spinner').show()

  new window.VoluntaryMusicMetadataEnrichment.Library.YearsInReview.IndexView(true)
  new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView()
  new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.NewView()