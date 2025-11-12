import { Controller } from "@hotwired/stimulus"

// Flexy Sidebar Controller
export default class extends Controller {
  static targets = ["logoText", "profileInfo", "navText", "sectionTitle", "profile", "footer"]
  static values = {
    expanded: { type: Boolean, default: true }
  }

  connect() {
    // 檢查 localStorage 中的狀態
    const savedState = localStorage.getItem('sidebarExpanded')
    if (savedState !== null) {
      this.expandedValue = savedState === 'true'
    }

    this.updateSidebarState()
  }

  toggle(event) {
    event?.preventDefault()
    this.expandedValue = !this.expandedValue
    this.updateSidebarState()

    // 儲存狀態到 localStorage
    localStorage.setItem('sidebarExpanded', this.expandedValue)
  }

  updateSidebarState() {
    if (this.expandedValue) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  expand() {
    // 展開側邊欄
    this.element.classList.remove('collapsed')
    this.element.style.width = '270px'

    // 顯示文字元素
    this.logoTextTargets.forEach(el => el.classList.remove('hidden'))
    this.navTextTargets.forEach(el => el.classList.remove('hidden'))
    this.sectionTitleTargets.forEach(el => el.classList.remove('hidden'))

    if (this.hasProfileInfoTarget) {
      this.profileInfoTarget.classList.remove('hidden')
    }

    if (this.hasFooterTarget) {
      this.footerTarget.classList.remove('text-center')
    }

    // 調整主內容區域
    const mainContent = document.querySelector('.flexy-main')
    if (mainContent) {
      mainContent.style.marginLeft = '270px'
    }
  }

  collapse() {
    // 收合側邊欄
    this.element.classList.add('collapsed')
    this.element.style.width = '80px'

    // 隱藏文字元素
    this.logoTextTargets.forEach(el => el.classList.add('hidden'))
    this.navTextTargets.forEach(el => el.classList.add('hidden'))
    this.sectionTitleTargets.forEach(el => el.classList.add('hidden'))

    if (this.hasProfileInfoTarget) {
      this.profileInfoTarget.classList.add('hidden')
    }

    if (this.hasFooterTarget) {
      this.footerTarget.classList.add('text-center')
    }

    // 調整主內容區域
    const mainContent = document.querySelector('.flexy-main')
    if (mainContent) {
      mainContent.style.marginLeft = '80px'
    }
  }

  // 處理行動裝置的側邊欄
  handleMobileToggle() {
    if (window.innerWidth < 768) {
      this.element.classList.toggle('mobile-open')

      // 創建遮罩層
      if (this.element.classList.contains('mobile-open')) {
        const overlay = document.createElement('div')
        overlay.className = 'sidebar-overlay'
        overlay.addEventListener('click', () => this.handleMobileToggle())
        document.body.appendChild(overlay)
      } else {
        const overlay = document.querySelector('.sidebar-overlay')
        if (overlay) overlay.remove()
      }
    }
  }
}