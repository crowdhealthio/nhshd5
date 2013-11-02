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
  var latitude=$("#latitude").innerHTML;
  var longitude=$("#longitude").innerHTML;
  $.getJSON("/places.json?lat="+latitude+"&long="+longitude, {data: "value"}, function(json) {
     alert(json);
  });
}

function storePosition(position) {
  var latitude=$("#latitude");
  var longitude=$("#longitude");
  latitude.innerHTML = position.coords.latitude;
  longitude.innerHTML = position.coords.longitude; 
  getPlaces();
}