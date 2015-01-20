$(document).ready ->
  $(document.body).on "change", "select[name^=\"year\"]", ->
    $.ajax(
      url: "/music_metadata_enrichment/groups/" + group_id + "/releases"
      data:
        year: $(this).val()
      type: "GET"
      dataType: "html"
    ).success (data) ->
      $("#releases").empty()
      $("#releases").append data
      return
