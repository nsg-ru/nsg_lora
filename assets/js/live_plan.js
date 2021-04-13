import L from "leaflet"
import "leaflet.fullscreen/Control.FullScreen"

global.initLivePlan = function() {
  let live_plan = document.getElementById("live-plan")
  let fp_coord = [live_plan.dataset.y, live_plan.dataset.x]

  var plan = L.map('live-plan', {
    crs: L.CRS.Simple,
    minZoom: 4,
    maxZoom: 10
  });

  var bounds = [
    [0, 0],
    [13.35, 25.84]
  ];
  var image = L.imageOverlay('/images/plan_nsg.jpg', bounds).addTo(plan);
  plan.fitBounds(bounds);

  let fpLayerGroup = L.layerGroup().addTo(plan);

  let tpIconDiv = `<div
  class="h-8 w-8 rounded-full bg-gray-900 bg-opacity-50 border border-gray-900">
  </div>`
  let tpIcon = function() {
    return L.divIcon({
      html: tpIconDiv,
      className: 'nsg-sensor-icon',
      iconAnchor: [16, 16]
    });
  }

  let fpIconDiv = `<div
  class="h-2 w-2 rounded-full bg-gray-900 bg-opacity-50 border border-gray-900">
  </div>`
  let fpIcon = function() {
    return L.divIcon({
      html: fpIconDiv,
      className: 'nsg-sensor-icon',
      iconAnchor: [4, 4]
    });
  }

  let lpIconDiv = `<div
  class="h-8 w-8 rounded-full bg-red-500 bg-opacity-50 border border-gray-900">
  </div>`
  let lpIcon = function() {
    return L.divIcon({
      html: lpIconDiv,
      className: 'nsg-sensor-icon',
      iconAnchor: [16, 16]
    });
  }


  let tpMarker = L.marker(L.latLng(fp_coord), {
    icon: tpIcon(),
    draggable: 'true'
  }).addTo(plan);

  plan.addControl(new L.Control.FullScreen());

  tpMarker.on('dragend', function(event) {
    var position = tpMarker.getLatLng();
    var event = new CustomEvent('liveview-plan-event', {
      'detail': {
        event: 'tp_position',
        payload: position
      }
    });
    dispatchEvent(event);
  });

  global.addFpToPlan = function(payload) {
    L.marker(L.latLng(payload.position), {
      icon: fpIcon(),
    }).addTo(fpLayerGroup);
  }
  global.clearAllFp = function() {
    fpLayerGroup.clearLayers();
  }

  global.addMarkerToPlan = function(payload) {
    L.marker(L.latLng(payload.position), {
      icon: lpIcon(),
    }).addTo(plan);
  }
}

// plan.setView( [70, 120], 1);
