import L from "leaflet"
import "leaflet.fullscreen/Control.FullScreen"

var plan = L.map('live-plan', {
  crs: L.CRS.Simple,
  minZoom: -1,
  maxZoom: 10
});


var bounds = [
  [0, 0],
  [9, 16]
];
var image = L.imageOverlay('/images/bogatka.png', bounds).addTo(plan);
plan.fitBounds(bounds);


let snIcon = function() {
  return L.divIcon({
    html: `<div class="flex flex-col justify-center h-8 w-8 rounded-full bg-red-500 bg-opacity-50 border border-gray-900"></div>`,
    className: 'nsg-sensor-icon',
    iconAnchor: [16, 16]
  });
}


var sol = L.latLng([4.50, 8.00]);
L.marker(sol, {
  icon: snIcon(),
  draggable: 'true'
}).addTo(plan);

// plan.setView( [70, 120], 1);
