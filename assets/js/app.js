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
      this.input.dispatchEvent(new Event("input", {bubbles: true}))
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
    this.draggingPreset = null
    this.dropIndicator = document.createElement("div")
    this.dropIndicator.className = "col-span-12 h-2 rounded-full bg-primary/70 shadow-sm shadow-primary/30"

    this.clearDropIndicator = () => {
      if (this.dropIndicator.parentNode) this.dropIndicator.remove()
    }

    this.targetPlacement = event => {
      const target = event.target.closest("[data-section-id]")
      if (!target || target.dataset.sectionId === this.draggingId) return {target: null, targetId: null, placement: "after"}

      const placement = event.clientY < target.getBoundingClientRect().top + target.offsetHeight / 2 ? "before" : "after"
      return {target, targetId: target.dataset.sectionId, placement}
    }

    this.showDropIndicator = event => {
      const {target, placement} = this.targetPlacement(event)

      if (!target) {
        this.el.appendChild(this.dropIndicator)
        return
      }

      if (placement === "before") {
        target.before(this.dropIndicator)
      } else {
        target.after(this.dropIndicator)
      }
    }

    this.handleDragStart = event => {
      const preset = event.target.closest("[data-preset-id]")
      if (preset) {
        this.draggingPreset = preset.dataset.presetId
        event.dataTransfer.effectAllowed = "copy"
        event.dataTransfer.setData("text/plain", `preset:${this.draggingPreset}`)
        preset.classList.add("opacity-60")
        return
      }

      const item = event.target.closest("[data-section-id]")
      if (!item) return

      this.draggingId = item.dataset.sectionId
      event.dataTransfer.effectAllowed = "move"
      event.dataTransfer.setData("text/plain", this.draggingId)
      item.classList.add("opacity-60")
    }

    this.handleDragEnd = event => {
      const preset = event.target.closest("[data-preset-id]")
      if (preset) preset.classList.remove("opacity-60")
      const item = event.target.closest("[data-section-id]")
      if (item) item.classList.remove("opacity-60")
      this.draggingId = null
      this.draggingPreset = null
      this.clearDropIndicator()
    }

    document.addEventListener("dragstart", this.handleDragStart)
    document.addEventListener("dragend", this.handleDragEnd)

    this.el.addEventListener("dragover", event => {
      if (this.draggingId || this.draggingPreset) {
        event.preventDefault()
        this.showDropIndicator(event)
      }
    })

    this.el.addEventListener("drop", event => {
      if (!this.draggingId && !this.draggingPreset) return
      event.preventDefault()

      const {targetId, placement} = this.targetPlacement(event)
      this.clearDropIndicator()

      if (this.draggingPreset) {
        this.pushEvent("insert_preset_section", {preset: this.draggingPreset, target_id: targetId, placement})
        this.draggingPreset = null
        return
      }

      const ids = Array.from(this.el.querySelectorAll("[data-section-id]")).map(item => item.dataset.sectionId)
      const nextIds = ids.filter(id => id !== this.draggingId)

      if (targetId && targetId !== this.draggingId) {
        const targetIndex = nextIds.indexOf(targetId)
        const insertIndex = placement === "after" ? targetIndex + 1 : targetIndex
        nextIds.splice(insertIndex, 0, this.draggingId)
      } else {
        nextIds.push(this.draggingId)
      }

      this.pushEvent("reorder_sections", {ids: nextIds})
      this.draggingId = null
    })
  },

  destroyed() {
    document.removeEventListener("dragstart", this.handleDragStart)
    document.removeEventListener("dragend", this.handleDragEnd)
    this.clearDropIndicator()
  },
}

const CollectionItemSlugSync = {
  mounted() {
    this.slugEdited = false
    this.syncingSlug = false
    this.boundSlugInput = null
    this.boundSourceInput = null

    this.slugify = value =>
      value
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9_-]+/g, "-")
        .replace(/^-+|-+$/g, "")

    this.updateSlug = () => {
      if (!this.slugInput || !this.sourceInput || this.slugEdited) return
      this.slugInput.value = this.slugify(this.sourceInput.value || "")
      this.syncingSlug = true
      this.slugInput.dispatchEvent(new Event("input", {bubbles: true}))
      this.syncingSlug = false
    }

    this.handleSlugInput = () => {
      if (this.syncingSlug) return
      this.slugEdited = true
    }

    this.bindInputs = () => {
      this.slugInput = this.el.querySelector("input[name='collection_item[slug]']")
      this.sourceInput = this.el.querySelector("[data-slug-source='true']")

      if (this.slugInput && this.slugInput !== this.boundSlugInput) {
        this.slugInput.addEventListener("input", this.handleSlugInput)
        this.boundSlugInput = this.slugInput
      }

      if (this.sourceInput && this.sourceInput !== this.boundSourceInput) {
        this.sourceInput.addEventListener("input", this.updateSlug)
        this.sourceInput.addEventListener("change", this.updateSlug)
        this.boundSourceInput = this.sourceInput
      }
    }

    this.bindInputs()
  },

  updated() {
    this.bindInputs()
  },
}

const BuilderCanvas = {
  mounted() {
    this.el.addEventListener("click", event => {
      if (event.target.closest("#builder-palette")) return
      if (event.target.closest("#builder-seo-panel")) return
      if (event.target.closest("#builder-section-properties-panel")) return
      if (event.target.closest("#builder-inspector-sidebar")) return
      if (event.target.closest("[id^='builder-section-bottom-sheet-']")) return
      if (event.target.closest("[data-builder-page-element]")) return
      if (event.target.closest("[data-builder-ignore-click]")) return
      if (event.target.matches("input[type='file'][data-phx-upload-ref]")) return

      const section = event.target.closest("[data-section-id]")
      const element = event.target.closest("[data-builder-element]")

      if (section && element) {
        const kind = element.dataset.builderElement || "section"

        if (kind !== "text") event.preventDefault()

        this.pushEvent("select_canvas_element", {
          section_id: section.dataset.sectionId,
          kind,
          field: element.dataset.builderField || null,
        })
        return
      }

      if (section) return

      this.pushEvent("clear_section_focus", {})
    })
  },
}

const AstContentEditable = {
  mounted() {
    this.lastSent = this.el.textContent || ""
    this.timer = null

    this.pushText = () => {
      const value = this.el.textContent || ""
      if (value === this.lastSent) return
      this.lastSent = value
      this.pushEvent("update_text_property", {
        id: this.el.dataset.nodeId,
        property: this.el.dataset.property || "text",
        value,
      })
    }

    this.el.addEventListener("input", () => {
      window.clearTimeout(this.timer)
      this.timer = window.setTimeout(this.pushText, 1200)
    })

    this.el.addEventListener("blur", () => {
      window.clearTimeout(this.timer)
      this.pushText()
    })

    this.el.addEventListener("paste", event => {
      event.preventDefault()
      const text = (event.clipboardData || window.clipboardData).getData("text/plain")
      document.execCommand("insertText", false, text)
    })
  },

  destroyed() {
    window.clearTimeout(this.timer)
  },
}

const AutoGrowTextArea = {
  mounted() {
    this.resize = () => {
      this.el.style.height = "auto"
      this.el.style.height = `${this.el.scrollHeight}px`
    }

    this.el.addEventListener("input", this.resize)
    this.resize()
  },

  updated() {
    this.resize()
  },

  destroyed() {
    this.el.removeEventListener("input", this.resize)
  },
}

const scheduleFlashDismissals = root => {
  root.querySelectorAll("[data-auto-dismiss-flash='true']").forEach(flash => {
    if (flash.dataset.dismissScheduled === "true") return

    flash.dataset.dismissScheduled = "true"
    window.setTimeout(() => {
      if (!flash.isConnected || flash.hidden) return

      const closeButton = flash.querySelector("button[aria-label]")
      if (closeButton) {
        closeButton.click()
      } else {
        flash.remove()
      }
    }, 3000)
  })
}

const ensureConfirmDialog = () => {
  let dialog = document.getElementById("app-confirm-dialog")
  if (dialog) return dialog

  dialog = document.createElement("dialog")
  dialog.id = "app-confirm-dialog"
  dialog.className = "modal"
  dialog.innerHTML = `
    <div class="modal-box max-w-md">
      <h3 class="text-lg font-semibold">Confirm action</h3>
      <p class="py-4 text-sm text-base-content/70" data-confirm-message></p>
      <div class="modal-action">
        <button type="button" class="btn btn-ghost" data-confirm-cancel>Cancel</button>
        <button type="button" class="btn btn-error" data-confirm-accept>Confirm</button>
      </div>
    </div>
    <form method="dialog" class="modal-backdrop">
      <button>close</button>
    </form>
  `
  document.body.appendChild(dialog)
  return dialog
}

document.addEventListener("click", event => {
  const trigger = event.target.closest("[data-confirm]")
  if (!trigger || trigger.dataset.confirmed === "true") {
    if (trigger) delete trigger.dataset.confirmed
    return
  }

  event.preventDefault()
  event.stopImmediatePropagation()

  const dialog = ensureConfirmDialog()
  const message = dialog.querySelector("[data-confirm-message]")
  const accept = dialog.querySelector("[data-confirm-accept]")
  const cancel = dialog.querySelector("[data-confirm-cancel]")

  message.textContent = trigger.dataset.confirm || "Are you sure?"

  const cleanup = () => {
    accept.removeEventListener("click", confirmAction)
    cancel.removeEventListener("click", cancelAction)
  }

  const cancelAction = () => {
    cleanup()
    dialog.close()
  }

  const confirmAction = () => {
    cleanup()
    dialog.close()
    const confirmMessage = trigger.dataset.confirm
    trigger.dataset.confirmed = "true"
    delete trigger.dataset.confirm
    trigger.click()
    window.setTimeout(() => {
      if (confirmMessage !== undefined) trigger.dataset.confirm = confirmMessage
    }, 0)
  }

  accept.addEventListener("click", confirmAction, {once: true})
  cancel.addEventListener("click", cancelAction, {once: true})
  dialog.showModal()
}, true)

document.addEventListener("DOMContentLoaded", () => scheduleFlashDismissals(document))
window.addEventListener("phx:page-loading-stop", () => scheduleFlashDismissals(document))
new MutationObserver(mutations => {
  mutations.forEach(mutation => {
    mutation.addedNodes.forEach(node => {
      if (node.nodeType === Node.ELEMENT_NODE) scheduleFlashDismissals(node)
    })
  })
}).observe(document.documentElement, {childList: true, subtree: true})

const AstBuilderCanvas = {
  mounted() {
    this.draggingNodeId = null
    this.draggingPalette = null
    this.dropIndicator = document.createElement("div")
    this.dropIndicator.className = "pointer-events-none h-2 rounded-full bg-primary/70 shadow shadow-primary/30"

    this.clearDropIndicator = () => {
      if (this.dropIndicator.parentNode) this.dropIndicator.remove()
    }

    this.closestDropTarget = event => {
      return event.target.closest("[data-drop-target-id]") || this.el.querySelector("#editor-canvas-root")
    }

    this.dropPosition = (event, target) => {
      if (!target || target.dataset.dropTargetId === "root") return "into"
      const rect = target.getBoundingClientRect()
      if (event.clientY < rect.top + rect.height * 0.25) return "before"
      if (event.clientY > rect.bottom - rect.height * 0.25) return "after"
      return "into"
    }

    this.showDropIndicator = event => {
      const target = this.closestDropTarget(event)
      const position = this.dropPosition(event, target)
      if (!target || target.dataset.dropTargetId === "root") {
        this.el.querySelector("#editor-canvas-root")?.appendChild(this.dropIndicator)
        return
      }

      if (position === "before") target.before(this.dropIndicator)
      if (position === "after") target.after(this.dropIndicator)
      if (position === "into") target.appendChild(this.dropIndicator)
    }

    this.handleDragStart = event => {
      const paletteItem = event.target.closest("[data-palette-name]")
      if (paletteItem) {
        this.draggingPalette = {
          name: paletteItem.dataset.paletteName,
          variant: paletteItem.dataset.paletteVariant || "default",
        }
        event.dataTransfer.effectAllowed = "copy"
        event.dataTransfer.setData("text/plain", `palette:${this.draggingPalette.name}`)
        return
      }

      const node = event.target.closest("[data-node-id]")
      if (!node) return
      this.draggingNodeId = node.dataset.nodeId
      event.dataTransfer.effectAllowed = "move"
      event.dataTransfer.setData("text/plain", this.draggingNodeId)
    }

    this.handleDragEnd = () => {
      this.draggingNodeId = null
      this.draggingPalette = null
      this.clearDropIndicator()
    }

    this.handleKeyDown = event => {
      const key = event.key.toLowerCase()
      if ((event.metaKey || event.ctrlKey) && key === "z" && event.shiftKey) {
        event.preventDefault()
        this.pushEvent("redo", {})
      } else if ((event.metaKey || event.ctrlKey) && key === "z") {
        event.preventDefault()
        this.pushEvent("undo", {})
      }
    }

    this.scrollNodeIntoView = ({id, source}) => {
      window.requestAnimationFrame(() => {
        const canvasNode = document.getElementById(`canvas-node-${id}`)
        const layerNode = document.querySelector(`[data-layer-node-id="${id}"]`)

        if (source === "layers") {
          canvasNode?.scrollIntoView({block: "center", inline: "nearest", behavior: "smooth"})
          return
        }

        layerNode?.scrollIntoView({block: "center", inline: "nearest", behavior: "smooth"})
      })
    }

    document.addEventListener("dragstart", this.handleDragStart)
    document.addEventListener("dragend", this.handleDragEnd)
    window.addEventListener("keydown", this.handleKeyDown)
    this.handleEvent("builder:focus-node", this.scrollNodeIntoView)

    this.el.addEventListener("dragover", event => {
      if (!this.draggingNodeId && !this.draggingPalette) return
      event.preventDefault()
      this.showDropIndicator(event)
    })

    this.el.addEventListener("drop", event => {
      if (!this.draggingNodeId && !this.draggingPalette) return
      event.preventDefault()

      const target = this.closestDropTarget(event)
      const targetId = target?.dataset.dropTargetId || "root"
      const position = this.dropPosition(event, target)
      this.clearDropIndicator()

      if (this.draggingPalette) {
        this.pushEvent("drop_palette_node", {
          name: this.draggingPalette.name,
          variant: this.draggingPalette.variant,
          target_id: targetId,
          position,
        })
        this.draggingPalette = null
        return
      }

      this.pushEvent("drop_node", {
        dragged_id: this.draggingNodeId,
        target_id: targetId,
        position,
      })
      this.draggingNodeId = null
    })
  },

  destroyed() {
    document.removeEventListener("dragstart", this.handleDragStart)
    document.removeEventListener("dragend", this.handleDragEnd)
    window.removeEventListener("keydown", this.handleKeyDown)
    this.clearDropIndicator()
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {
    ...colocatedHooks,
    AstBuilderCanvas,
    AstContentEditable,
    AutoGrowTextArea,
    BuilderCanvas,
    BuilderSortable,
    ContentEditableInput,
    CollectionItemSlugSync,
  },
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
