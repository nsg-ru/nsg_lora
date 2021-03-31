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
}
