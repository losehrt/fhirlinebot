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

    // Initialize based on screen size
    this.handleResize()

    // Add resize listener
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  disconnect() {
    // Clean up resize listener
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler)
    }
  }

  handleResize() {
    const isMobile = window.innerWidth < 768

    if (isMobile) {
      // On mobile, ensure sidebar is properly hidden
      this.setupMobileState()
    } else {
      // On desktop, apply saved state
      this.updateSidebarState()
    }
  }

  setupMobileState() {
    const sidebar = this.hasSidebarTarget ? this.sidebarTarget : this.element.querySelector('.sidebar-panel')
    if (!sidebar) return

    // Remove any desktop-specific classes
    sidebar.classList.remove('w-20', 'w-[270px]')

    // Hide text elements by default on mobile
    this.navTextTargets.forEach(el => el.classList.add('hidden'))
    if (this.hasProfileInfoTarget) {
      this.profileInfoTarget.classList.add('hidden')
    }

    // Show mobile logo on navbar, hide sidebar logos
    if (this.hasLogoExpandedTarget && this.hasLogoCollapsedTarget) {
      this.logoExpandedTarget.style.display = 'none'
      this.logoCollapsedTarget.style.display = 'none'
    }

    // Ensure margin is reset for mobile
    const mainContent = document.querySelector('main')?.parentElement
    if (mainContent) {
      mainContent.style.marginLeft = '0'
      mainContent.classList.remove('ml-20', 'ml-[270px]')
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
      const sidebar = this.hasSidebarTarget ? this.sidebarTarget : this.element.querySelector('.sidebar-panel')
      if (!sidebar) return

      sidebar.classList.toggle('mobile-open')

      // Show/hide elements when mobile sidebar toggles
      if (sidebar.classList.contains('mobile-open')) {
        // Restore sidebar width for mobile
        sidebar.classList.add('w-[270px]')

        // Show expanded logo for mobile menu
        if (this.hasLogoExpandedTarget) {
          this.logoExpandedTarget.style.display = 'block'
        }
        if (this.hasLogoCollapsedTarget) {
          this.logoCollapsedTarget.style.display = 'none'
        }

        // Show all text when mobile menu is open
        this.navTextTargets.forEach(el => el.classList.remove('hidden'))
        if (this.hasProfileInfoTarget) {
          this.profileInfoTarget.classList.remove('hidden')
        }

        // Create overlay
        const overlay = document.createElement('div')
        overlay.className = 'sidebar-overlay'
        overlay.addEventListener('click', () => this.handleMobileToggle())
        document.body.appendChild(overlay)
      } else {
        // Remove width class
        sidebar.classList.remove('w-[270px]')

        // Hide logos when mobile menu is closed
        if (this.hasLogoExpandedTarget && this.hasLogoCollapsedTarget) {
          this.logoExpandedTarget.style.display = 'none'
          this.logoCollapsedTarget.style.display = 'none'
        }

        // Hide text elements when mobile menu is closed
        this.navTextTargets.forEach(el => el.classList.add('hidden'))
        if (this.hasProfileInfoTarget) {
          this.profileInfoTarget.classList.add('hidden')
        }

        // Remove overlay
        const overlay = document.querySelector('.sidebar-overlay')
        if (overlay) overlay.remove()
      }
    }
  }
}