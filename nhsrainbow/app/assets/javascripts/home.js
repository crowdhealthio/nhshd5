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
    $("#results").append("<table>");
    $.each(json, function(i, item) {
      $("#results").append('<tr><td><a href="/places/'+item.id+'">' + item.name +'</a></td></tr>');
    });
    $("#results").append("</table>");
  });
}

function storePosition(position) {
  var latitude=$("#latitude");
  var longitude=$("#longitude");
  latitude.val(position.coords.latitude);
  longitude.val(position.coords.longitude); 
  getPlaces();
}