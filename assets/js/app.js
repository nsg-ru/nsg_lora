// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import 'alpinejs'

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {
  Socket
} from "phoenix"
import NProgress from "nprogress"
import {
  LiveSocket
} from "phoenix_live_view"

let Hooks = {}

Hooks.ToggleTheme = {
  set_theme(el) {
    let html = document.querySelector("html")
    if (el.classList.contains("hidden")) {
      html.classList.add("dark")
    } else {
      html.classList.remove("dark")
    }
  },
  mounted() {
    this.set_theme(this.el)
  },
  updated() {
    this.set_theme(this.el)
    // let html = document.querySelector("html")
    // if (this.el.classList.contains("hidden")) {
    //   html.classList.add("dark")
    // } else {
    //   html.classList.remove("dark")
    // }
  }
}

Hooks.Flash = {
  timeout: null,
  updated() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.closeFlash(), 7000)
  },
  closeFlash() {
      this.pushEvent("lv:clear-flash", {key: "info"})
  }
}


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    // make LiveView work nicely with alpinejs
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to);
      }
    },
  },
  hooks: Hooks,
  params: {
    _csrf_token: csrfToken
  }
})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
