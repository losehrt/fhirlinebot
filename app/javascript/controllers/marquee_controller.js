import { Controller } from "@hotwired/stimulus"

// Rails Blocks Marquee Controller
export default class extends Controller {
  static targets = ["track", "list"]
  static values = {
    speed: { type: Number, default: 20 },
    hoverSpeed: { type: Number, default: 0 },
    direction: { type: String, default: "left" }
  }

  connect() {
    this.duplicateList()
    this.startAnimation()
  }

  disconnect() {
    this.stopAnimation()
  }

  duplicateList() {
    if (!this.hasListTarget) return

    // Clone the list for seamless scrolling
    const clone = this.listTarget.cloneNode(true)
    clone.setAttribute('aria-hidden', 'true')
    this.trackTarget.appendChild(clone)
  }

  startAnimation() {
    if (!this.hasTrackTarget) return

    const direction = this.directionValue === "right" ? "" : "-"
    const duration = this.speedValue

    // Apply animation using transform
    this.trackTarget.style.animation = `scroll-${this.directionValue} ${duration}s linear infinite`

    // Inject keyframes if not already present
    this.injectKeyframes()
  }

  stopAnimation() {
    if (this.hasTrackTarget) {
      this.trackTarget.style.animationPlayState = "paused"
    }
  }

  pauseAnimation() {
    if (this.hoverSpeedValue === 0 && this.hasTrackTarget) {
      this.trackTarget.style.animationPlayState = "paused"
    }
  }

  resumeAnimation() {
    if (this.hasTrackTarget) {
      this.trackTarget.style.animationPlayState = "running"
    }
  }

  injectKeyframes() {
    const styleId = 'marquee-keyframes'
    if (document.getElementById(styleId)) return

    const style = document.createElement('style')
    style.id = styleId
    style.textContent = `
      @keyframes scroll-left {
        0% { transform: translateX(0); }
        100% { transform: translateX(-50%); }
      }
      @keyframes scroll-right {
        0% { transform: translateX(-50%); }
        100% { transform: translateX(0); }
      }
    `
    document.head.appendChild(style)
  }
}