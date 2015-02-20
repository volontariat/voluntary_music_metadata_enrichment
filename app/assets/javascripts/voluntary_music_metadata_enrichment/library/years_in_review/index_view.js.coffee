window.VoluntaryMusicMetadataEnrichment or= {}; window.VoluntaryMusicMetadataEnrichment.Library or= {}
window.VoluntaryMusicMetadataEnrichment.Library.YearsInReview or= {}

window.VoluntaryMusicMetadataEnrichment.Library.YearsInReview.IndexView = class IndexView
  constructor: (withAjaxLinks) ->
    if withAjaxLinks
      $(document.body).on "click", ".year_in_review_music_releases_link", (event) ->
        $this = $(this)
        $this.find('.ajax_spinner').show()
        
        $.ajax(url: $this.attr('href'), type: "GET", dataType: "html").done((data) =>
          $this.find('.ajax_spinner').hide()
          $($this.data("replace")).html(data)
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewReleases.IndexView.makeCollectionSortable()
        ).fail((data) =>
          $this.find('.ajax_spinner').hide()
          alert 'Failed to load top releases!'
        )
        event.preventDefault()  
      
      $(document.body).on "click", ".year_in_review_music_tracks_link", (event) ->
        $this = $(this)
        $this.find('.ajax_spinner').show()
        
        $.ajax(url: $this.attr('href'), type: "GET", dataType: "html").done((data) =>
          $this.find('.ajax_spinner').hide()
          $($this.data("replace")).html(data)
          window.VoluntaryMusicMetadataEnrichment.Library.YearInReviewTracks.IndexView.makeCollectionSortable()
        ).fail((data) =>
          $this.find('.ajax_spinner').hide()
          alert 'Failed to load top tracks!'
        )
        event.preventDefault()  
    
    $(document.body).on "ajax:beforeSend", ".publish_music_year_in_review_link", ->
      $(this).find('.ajax_spinner').show()   
        
    $(document.body).on "ajax:beforeSend", ".destroy_music_year_in_review_link", ->
      $(this).find('.ajax_spinner').show()    
        
    $(document.body).on "ajax:beforeSend", "#new_music_year_in_review_form", ->
      $("#years_in_review_spinner").show()