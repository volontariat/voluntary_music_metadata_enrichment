window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearsInReview or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearsInReview.IndexView = class IndexView
  constructor: (withAjaxLinks) ->
    if withAjaxLinks
      $(document.body).on "click", ".year_in_review_music_releases_link", (event) ->
        $this = $(this)
        
        $.ajax(url: $this.attr('href'), type: "GET", dataType: "html").success (data) ->
          $($this.data("replace")).html(data)
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.makeCollectionSortable()
          
        event.preventDefault()  
      
      $(document.body).on "click", ".year_in_review_music_tracks_link", (event) ->
        $this = $(this)
        
        $.ajax(url: $this.attr('href'), type: "GET", dataType: "html").success (data) ->
          $($this.data("replace")).html(data)
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.makeCollectionSortable()
          
        event.preventDefault()  
        
    $(document.body).on "ajax:beforeSend", "#new_music_year_in_review_form", ->
      $("#years_in_review_spinner").show()