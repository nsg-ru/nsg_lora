import L from "leaflet"
let livemap = document.getElementById("live-map")

if (livemap) {
  let bs_position = {lat: livemap.dataset.lat, lon: livemap.dataset.lon}

  let mymap = L.map('live-map').setView([bs_position.lat, bs_position.lon], 13);

  L.tileLayer(
    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      errorTileUrl: '/images/bogatka-o.png',
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(mymap);

  let sensorIcon = function(dbm, distance) {
    return L.divIcon({
      html: `<div class="flex flex-col justify-center h-8 w-8 rounded-full bg-red-500 bg-opacity-50 border border-gray-900  text-center text-gray-900 tracking-tighter leading-none"><div>${dbm}</div><div>${distance}</div></div>`,
      className: 'nsg-sensor-icon'
    });
  }

  let bsIcon = function() {
    return L.divIcon({
      html: `<div class="flex flex-col justify-center h-8 w-8 rounded-full bg-gray-500 bg-opacity-50 border border-gray-900  text-center text-gray-900"><div>BS</div></div>`,
      className: 'nsg-sensor-icon'
    });
  }



  let bsMarker = L.marker([bs_position.lat, bs_position.lon], {
    icon: bsIcon(),
    draggable: 'true'
  }).addTo(mymap);

  bsMarker.on('dragend', function(event) {
    var position = bsMarker.getLatLng();
    console.log(position)
    var event = new CustomEvent('liveview-map-bs-event', {
      'detail': {
        event: 'bs_position',
        payload: position
      }
    });
    dispatchEvent(event);

  });

  global.addMarkerToLiveMap = function(marker) {
    L.marker([marker.lat, marker.lon], {
        icon: sensorIcon(marker.rssi, marker.distance || ""),
      })
      .bindPopup(`${marker.date}<br>${marker.lat} ${marker.lon}<br>freq: ${marker.freq}<br>rssi: ${marker.rssi}<br>lsnr: ${marker.lsnr}`).openPopup()
      .addTo(mymap);
  }
}
