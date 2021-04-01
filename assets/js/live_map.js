import L from "leaflet"
let livemap = document.getElementById("live-map")

if (livemap) {
  let mymap = L.map('live-map').setView([55.7782, 37.7371], 13);

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

  let marker = {
    date: "2021-04-01T13:21:30",
    freq: 867.3,
    lat: 55.7775,
    lon: 37.7382,
    lsnr: 11,
    rssi: -43
  }

  L.marker([55.7782, 37.7371], {
      icon: sensorIcon(marker.rssi, marker.distance || ""),
    })
    .bindPopup(`${marker.date}<br>${marker.lat} ${marker.lon}<br>freq: ${marker.freq}<br>rssi: ${marker.rssi}<br>lsnr: ${marker.lsnr}`).openPopup()
    .addTo(mymap);


  global.addMarkerToLiveMap = function(marker) {
    console.log(marker)
    L.marker([marker.lat, marker.lon], {
        icon: sensorIcon(marker.rssi, marker.distance || ""),
      })
      .bindPopup(`${marker.date}<br>${marker.lat} ${marker.lon}<br>freq: ${marker.freq}<br>rssi: ${marker.rssi}<br>lsnr: ${marker.lsnr}`).openPopup()
      .addTo(mymap);
  }
}
