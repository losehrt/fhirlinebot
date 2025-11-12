import { Controller } from "@hotwired/stimulus"

// Rails Block Modal Controller
export default class extends Controller {
  static targets = ["modal", "backdrop"]

  connect() {
    // 初始化時隱藏 modal
    this.hide()
  }

  show(event) {
    event?.preventDefault()

    // 顯示背景和模態框
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("hidden")
    }
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
    }

    // 防止 body 滾動
    document.body.style.overflow = "hidden"
  }

  hide(event) {
    event?.preventDefault()

    // 隱藏背景和模態框
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.add("hidden")
    }
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
    }

    // 恢復 body 滾動
    document.body.style.overflow = ""
  }

  // 點擊背景時關閉
  hideOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.hide(event)
    }
  }

  // ESC 鍵關閉
  hideOnEscape(event) {
    if (event.key === "Escape") {
      this.hide(event)
    }
  }
}