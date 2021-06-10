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
import "./live_map"
import "./live_plan"

import * as monaco from 'monaco-editor';
console.log("XXX",

  monaco.editor.create(document.getElementById('editor-bs'), {
    value: [
      '{',
      '"key": "value"',
      '}'
    ].join('\n'),
    language: 'json',
    wordWrap: 'on'
  })
)


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
  }
}

Hooks.Flash = {
  timeout: null,
  updated() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.closeFlash(), 7000)
  },
  closeFlash() {
    this.pushEvent("lv:clear-flash", {
      key: "info"
    })
  }
}

Hooks.FormChange = {
  mounted() {
    const liveView = this
    this.liveViewPushEvent = function (e) {
      liveView.pushEvent(e.detail.event, e.detail.payload)
    }
    window.addEventListener('liveview-push-event',
      this.liveViewPushEvent)
  },
  destroyed() {
    window.removeEventListener('liveview-push-event',
      this.liveViewPushEvent)
  }
}

Hooks.ScrollBottom = {
  mounted() {
    // this.el.scrollTop = this.el.scrollHeight
    setTimeout(() => this.el.scrollTop = this.el.scrollHeight, 0)
  },
  updated() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

Hooks.MapSightingsHandler = {
  mounted() {
    initLiveMap()
    const liveView = this
    this.liveViewPushEvent = function (e) {
      liveView.pushEvent(e.detail.event, e.detail.payload)
    }
    window.addEventListener('liveview-map-bs-event',
      this.liveViewPushEvent)

    this.handleEvent('new_sighting', addMarkerToLiveMap);
    this.handleEvent('clear_markers', clearAllMarkers);
  },
  destroyed() {
    window.removeEventListener('liveview-map-bs-event',
      this.liveViewPushEvent)
  }
};


Hooks.LocalizationHandler = {
  mounted() {
    initLivePlan()
    const liveView = this
    this.liveViewPushEvent = function (e) {
      liveView.pushEvent(e.detail.event, e.detail.payload)
    }
    window.addEventListener('liveview-plan-event',
      this.liveViewPushEvent)

    this.handleEvent('update_tp', updateTpMarker);
    this.handleEvent('new_position', addMarkerToPlan);
    this.handleEvent('fp_position', addFpToPlan);
    this.handleEvent('clear_fp_position', clearAllFp);
  },
  destroyed() {
    window.removeEventListener('liveview-plan-event',
      this.liveViewPushEvent)
  }
};


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
window.addEventListener("phx:page-loading-start", _info => NProgress.start())
window.addEventListener("phx:page-loading-stop", _info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
