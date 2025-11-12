import { Controller } from "@hotwired/stimulus"

// Flexy Sidebar Controller
export default class extends Controller {
  static targets = ["sidebar", "logoText", "logoExpanded", "logoCollapsed", "profileInfo", "navText", "sectionTitle", "profile", "footer"]
  static values = {
    expanded: { type: Boolean, default: true }
  }

  connect() {
    // 檢查 localStorage 中的狀態
    const savedState = localStorage.getItem('sidebarExpanded')
    if (savedState !== null) {
      this.expandedValue = savedState === 'true'
    }

    // Only update sidebar state on desktop
    if (window.innerWidth >= 768) {
      this.updateSidebarState()
    } else {
      // On mobile, ensure margin is reset
      const mainContent = document.querySelector('.flexy-main')
      if (mainContent) {
        mainContent.style.marginLeft = '0'
      }
    }
  }

  toggle(event) {
    event?.preventDefault()

    // Check if we're on mobile
    if (window.innerWidth < 768) {
      this.handleMobileToggle()
    } else {
      this.expandedValue = !this.expandedValue
      this.updateSidebarState()

      // 儲存狀態到 localStorage
      localStorage.setItem('sidebarExpanded', this.expandedValue)
    }
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
    const sidebar = this.hasSidebarTarget ? this.sidebarTarget : this.element.querySelector('.sidebar-panel')
    if (!sidebar) return

    // Update sidebar width
    sidebar.classList.remove('w-20')
    sidebar.classList.add('w-[270px]')

    // Update logo visibility
    if (this.hasLogoExpandedTarget && this.hasLogoCollapsedTarget) {
      this.logoExpandedTarget.style.display = 'block'
      this.logoCollapsedTarget.style.display = 'none'
    }

    // Show text elements
    this.navTextTargets.forEach(el => el.classList.remove('hidden'))
    if (this.hasProfileInfoTarget) {
      this.profileInfoTarget.classList.remove('hidden')
    }

    // Restore profile and nav items alignment
    const profile = sidebar.querySelector('.sidebar-profile')
    if (profile) {
      profile.classList.remove('justify-center')
      profile.classList.add('gap-3')
    }

    const navItems = sidebar.querySelectorAll('.nav-item')
    navItems.forEach(item => {
      item.classList.remove('justify-center')
      item.classList.add('gap-3')
    })

    // Update main content margin
    if (window.innerWidth >= 768) {
      const mainContent = document.querySelector('main').parentElement
      if (mainContent) {
        mainContent.classList.remove('ml-20')
        mainContent.classList.add('ml-[270px]')
      }
    }
  }

  collapse() {
    // 收合側邊欄
    const sidebar = this.hasSidebarTarget ? this.sidebarTarget : this.element.querySelector('.sidebar-panel')
    if (!sidebar) return

    // Update sidebar width
    sidebar.classList.remove('w-[270px]')
    sidebar.classList.add('w-20')

    // Update logo visibility
    if (this.hasLogoExpandedTarget && this.hasLogoCollapsedTarget) {
      this.logoExpandedTarget.style.display = 'none'
      this.logoCollapsedTarget.style.display = 'block'
    }

    // Hide text elements
    this.navTextTargets.forEach(el => el.classList.add('hidden'))
    if (this.hasProfileInfoTarget) {
      this.profileInfoTarget.classList.add('hidden')
    }

    // Center profile and nav items when collapsed
    const profile = sidebar.querySelector('.sidebar-profile')
    if (profile) {
      profile.classList.add('justify-center')
      profile.classList.remove('gap-3')
    }

    const navItems = sidebar.querySelectorAll('.nav-item')
    navItems.forEach(item => {
      item.classList.add('justify-center')
      item.classList.remove('gap-3')
    })

    // Update main content margin
    if (window.innerWidth >= 768) {
      const mainContent = document.querySelector('main').parentElement
      if (mainContent) {
        mainContent.classList.remove('ml-[270px]')
        mainContent.classList.add('ml-20')
      }
    }
  }

  // 處理行動裝置的側邊欄
  handleMobileToggle() {
    if (window.innerWidth < 768) {
      const sidebar = this.hasSidebarTarget ? this.sidebarTarget : this.element.querySelector('.flexy-sidebar')
      if (!sidebar) return

      sidebar.classList.toggle('mobile-open')

      // 創建遮罩層
      if (sidebar.classList.contains('mobile-open')) {
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