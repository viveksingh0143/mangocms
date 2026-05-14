// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/mangocms"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const ContentEditableInput = {
  mounted() {
    this.input = document.getElementById(this.el.dataset.inputId)
    this.multiline = this.el.dataset.multiline === "true"
    this.placeholder = this.el.dataset.placeholder || ""
    this.placeholderActive = this.el.dataset.placeholderActive === "true"

    this.syncInput = () => {
      if (!this.input) return

      let text = this.el.innerText.replace(/\u00a0/g, " ")
      if (!this.multiline) text = text.replace(/\s+/g, " ").trim()
      if (this.placeholderActive && text === this.placeholder) text = ""
      this.input.value = text
    }

    this.el.addEventListener("focus", () => {
      if (!this.placeholderActive) return

      this.el.innerText = ""
      this.placeholderActive = false
      this.syncInput()
    })

    this.el.addEventListener("input", this.syncInput)
    this.el.addEventListener("blur", () => {
      const text = this.el.innerText.replace(/\u00a0/g, " ").trim()

      if (text === "" && this.placeholder !== "") {
        this.placeholderActive = true
        this.el.innerText = this.placeholder
      }

      this.syncInput()
    })

    this.el.addEventListener("keydown", event => {
      if (!this.multiline && event.key === "Enter") {
        event.preventDefault()
        this.el.blur()
      }
    })

    this.el.addEventListener("paste", event => {
      event.preventDefault()
      const text = (event.clipboardData || window.clipboardData).getData("text/plain")
      document.execCommand("insertText", false, text)
      this.syncInput()
    })
  },

  updated() {
    this.input = document.getElementById(this.el.dataset.inputId)
  },
}

const BuilderSortable = {
  mounted() {
    this.draggingId = null

    this.el.addEventListener("dragstart", event => {
      const item = event.target.closest("[data-section-id]")
      if (!item) return

      this.draggingId = item.dataset.sectionId
      event.dataTransfer.effectAllowed = "move"
      event.dataTransfer.setData("text/plain", this.draggingId)
      item.classList.add("opacity-60")
    })

    this.el.addEventListener("dragend", event => {
      const item = event.target.closest("[data-section-id]")
      if (item) item.classList.remove("opacity-60")
      this.draggingId = null
    })

    this.el.addEventListener("dragover", event => {
      if (this.draggingId) event.preventDefault()
    })

    this.el.addEventListener("drop", event => {
      if (!this.draggingId) return
      event.preventDefault()

      const target = event.target.closest("[data-section-id]")
      const targetId = target && target.dataset.sectionId
      const ids = Array.from(this.el.querySelectorAll("[data-section-id]")).map(item => item.dataset.sectionId)
      const nextIds = ids.filter(id => id !== this.draggingId)

      if (targetId && targetId !== this.draggingId) {
        nextIds.splice(nextIds.indexOf(targetId), 0, this.draggingId)
      } else {
        nextIds.push(this.draggingId)
      }

      this.pushEvent("reorder_sections", {ids: nextIds})
      this.draggingId = null
    })
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, BuilderSortable, ContentEditableInput},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
