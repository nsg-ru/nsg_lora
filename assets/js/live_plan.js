import L from "leaflet"
import "leaflet.fullscreen/Control.FullScreen"

global.initLivePlan = function() {
  var plan = L.map('live-plan', {
    crs: L.CRS.Simple,
    minZoom: 4,
    maxZoom: 10
  });

  var bounds = [
    [0, 0],
    [15, 9]
  ];
  var image = L.imageOverlay('/images/plan.jpg', bounds).addTo(plan);
  plan.fitBounds(bounds);

  let tpIconSvg = `<svg xmlns="http://www.w3.org/2000/svg"
  class="h-10 w-10 text-red-900"
  fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
  d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
  d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
  </svg>`

  let tpIconDiv = `<div
  class="h-8 w-8 rounded-full bg-red-500 bg-opacity-50 border border-gray-900">
  </div>`

  let tpIcon = function() {
    return L.divIcon({
      html: tpIconDiv,
      className: 'nsg-sensor-icon',
      iconAnchor: [16, 16]
    });
  }


  let tpMarker = L.marker(L.latLng([0, 0]), {
    icon: tpIcon(),
    draggable: 'true'
  }).addTo(plan);

  plan.addControl(new L.Control.FullScreen());

  tpMarker.on('dragend', function(event) {
    var position = tpMarker.getLatLng();
    console.log(position)
    var event = new CustomEvent('liveview-plan-event', {
      'detail': {
        event: 'tp_position',
        payload: position
      }
    });
    dispatchEvent(event);
  });
}

// plan.setView( [70, 120], 1);
