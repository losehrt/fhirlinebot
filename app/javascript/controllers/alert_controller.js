import { Controller } from "@hotwired/stimulus"

// Rails Block Alert Controller
export default class extends Controller {
  static values = {
    autoDismiss: { type: Number, default: 0 }, // 自動關閉時間（毫秒）
    fadeOut: { type: Boolean, default: true }  // 是否漸隱
  }

  connect() {
    // 如果設定了自動關閉
    if (this.autoDismissValue > 0) {
      this.autoDismissTimer = setTimeout(() => {
        this.dismiss()
      }, this.autoDismissValue)
    }
  }

  disconnect() {
    // 清理計時器
    if (this.autoDismissTimer) {
      clearTimeout(this.autoDismissTimer)
    }
  }

  dismiss(event) {
    event?.preventDefault()

    if (this.fadeOutValue) {
      // 漸隱效果
      this.element.style.transition = "opacity 300ms ease-out"
      this.element.style.opacity = "0"

      setTimeout(() => {
        this.element.remove()
      }, 300)
    } else {
      // 直接移除
      this.element.remove()
    }
  }
}