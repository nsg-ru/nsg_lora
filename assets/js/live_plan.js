import L from "leaflet"
import "leaflet.fullscreen/Control.FullScreen"
import "leaflet-contextmenu/dist/leaflet.contextmenu"

global.initLivePlan = function() {
  let live_plan = document.getElementById("live-plan")
  let fp_coord = [live_plan.dataset.y, live_plan.dataset.x]

  var plan = L.map('live-plan', {
    crs: L.CRS.Simple,
    minZoom: 4,
    maxZoom: 10,
    contextmenu: true,
    //   contextmenuWidth: 140,
    contextmenuItems: [{
      text: 'Show coordinates',
      callback: showCoordinates
    }]
  });

  function showCoordinates(e) {
    alert(e.latlng.lat + ', ' + e.latlng.lng);
  }

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
  class="h-2 w-2 rounded-full bg-gray-900 bg-opacity-50">
  </div>`
  let fpIcon = function() {
    return L.divIcon({
      html: fpIconDiv,
      className: 'nsg-sensor-icon',
      iconAnchor: [3, 3]
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

  global.updateTpMarker = function(payload) {
    tpMarker.setLatLng(L.latLng(payload.position))
  }

  global.addFpToPlan = function(payload) {
    L.marker(L.latLng(payload.position), {
      icon: fpIcon(),
      contextmenu: true,
      contextmenuItems: [{
        text: 'Delete point',
        callback: deleteFP,
        context: {
          id: payload.id
        },
        index: 0
      }, {
        separator: true,
        index: 1
      }]
    }).addTo(fpLayerGroup);
  }

  function deleteFP(e) {
    console.log(e, this)
    var event = new CustomEvent('liveview-plan-event', {
      'detail': {
        event: 'delete_fp',
        payload: {
          id: this.id
        }
      }
    });
    dispatchEvent(event);
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
