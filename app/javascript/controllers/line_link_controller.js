import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async requestLink(event) {
    event.preventDefault()

    try {
      // Show loading state
      this.element.disabled = true
      this.element.textContent = "Connecting to LINE..."

      // Request authorization
      const response = await fetch("/user/request-line-link", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // Redirect to LINE authorization URL
      if (data.authorization_url) {
        window.location.href = data.authorization_url
      } else {
        throw new Error("No authorization URL received")
      }
    } catch (error) {
      console.error("Error requesting link:", error)
      alert("Failed to initialize link. Please try again.")

      // Reset button
      this.element.disabled = false
      this.element.innerHTML = `
        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 0C5.37 0 0 4.06 0 9.09c0 3.14 2.23 5.87 5.35 7.48v4.96c0 .59.6.95 1.13.65l3.1-1.96c.5.08 1.02.12 1.57.12 6.63 0 12-4.06 12-9.09S18.63 0 12 0m1.28 11.07H9.49v2.33H7.78v-2.33H6.07v-1.71h1.71V8.05h1.71v1.31h3.79v1.71m2.82 0h-4.96v-4.04h4.96v4.04z"/>
        </svg>
        Link with LINE
      `
    }
  }
}
