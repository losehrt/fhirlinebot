import { Controller } from "@hotwired/stimulus"

// Rails Block Tabs Controller
export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    defaultTab: { type: Number, default: 0 }
  }

  connect() {
    // 初始化顯示預設標籤頁
    this.showTab(this.defaultTabValue)
  }

  select(event) {
    event?.preventDefault()

    const tabIndex = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(tabIndex)
  }

  showTab(index) {
    // 更新標籤頁狀態
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.add("active", "border-blue-500", "text-blue-600")
        tab.classList.remove("border-transparent", "text-gray-500")
      } else {
        tab.classList.remove("active", "border-blue-500", "text-blue-600")
        tab.classList.add("border-transparent", "text-gray-500")
      }
    })

    // 顯示對應的面板
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}