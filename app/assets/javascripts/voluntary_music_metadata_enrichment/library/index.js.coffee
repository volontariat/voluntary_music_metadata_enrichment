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

  new window.VoluntaryMusicMetadataEnrichment.Library.YearsInReview.IndexView(true)
  new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView()
  new window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.NewView()