$(function() {
  if (navigator.geolocation)
  {
    navigator.geolocation.getCurrentPosition(storePosition);
  }
  else{
    alert("Geolocation is not supported by this browser.");
  }
});

function getPlaces() {
  var latitude=$("#latitude").val();
  var longitude=$("#longitude").val();
  $.getJSON("/places.json?lat="+latitude+"&long="+longitude, {data: "value"}, function(json) {
    $("#results").empty();
    $("#results").append('<div class="list-group">');
    $.each(json, function(i, item) {
      console.log(item)
      if(item.category) {
        console.log(item)
      }
      $("#results").append('<a class="list-group-item" href="/places/'+item.id+'">' + item.name +'</a>');
    });
    $("#results").append("</div>");
    if (json.length == 0) {
      $("#results").text("No results found");
    }
  });
}

function storePosition(position) {
  var latitude=$("#latitude");
  var longitude=$("#longitude");
  latitude.val(position.coords.latitude);
  longitude.val(position.coords.longitude);
  getPlaces();
}