import { Controller } from "@hotwired/stimulus"

// Rails Block Dropdown Controller
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.isOpen = false
    // 關閉 dropdown 當點擊外部
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  toggle(event) {
    event?.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (this.isOpen) return

    this.menuTarget.classList.remove("hidden")
    this.isOpen = true

    // 添加點擊外部監聽
    setTimeout(() => {
      document.addEventListener("click", this.boundClickOutside)
    }, 0)
  }

  close() {
    if (!this.isOpen) return

    this.menuTarget.classList.add("hidden")
    this.isOpen = false

    // 移除點擊外部監聽
    document.removeEventListener("click", this.boundClickOutside)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    // 清理事件監聽
    document.removeEventListener("click", this.boundClickOutside)
  }
}