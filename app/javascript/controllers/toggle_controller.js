import { Controller } from "@hotwired/stimulus"

// Rails Block Toggle (Switch) Controller
export default class extends Controller {
  static targets = ["switch", "input"]
  static values = {
    checked: { type: Boolean, default: false }
  }

  connect() {
    // 初始化狀態
    this.updateState()
  }

  toggle(event) {
    event?.preventDefault()

    // 切換狀態
    this.checkedValue = !this.checkedValue
    this.updateState()

    // 觸發 change 事件
    if (this.hasInputTarget) {
      const changeEvent = new Event("change", { bubbles: true })
      this.inputTarget.dispatchEvent(changeEvent)
    }
  }

  updateState() {
    // 更新視覺狀態
    if (this.hasSwitchTarget) {
      if (this.checkedValue) {
        this.switchTarget.classList.add("checked", "bg-blue-600")
        this.switchTarget.classList.remove("bg-gray-200")
      } else {
        this.switchTarget.classList.remove("checked", "bg-blue-600")
        this.switchTarget.classList.add("bg-gray-200")
      }
    }

    // 更新隱藏的 input 值
    if (this.hasInputTarget) {
      this.inputTarget.checked = this.checkedValue
    }
  }
}