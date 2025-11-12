import { Controller } from "@hotwired/stimulus"

// Setup controller for LINE OAuth configuration
export default class extends Controller {
  static targets = [
    "form",
    "channelId",
    "channelSecret",
    "validateBtn",
    "saveBtn",
    "testBtn",
    "clearBtn",
    "validationStatus"
  ]

  static values = {
    validatePath: String,
    testPath: String,
    clearPath: String,
    validated: { type: Boolean, default: false }
  }

  connect() {
    // Enable/disable save button based on validation status
    if (this.hasSaveBtnTarget) {
      this.saveBtnTarget.disabled = !this.validatedValue
    }
  }

  // Toggle password visibility
  toggleSecret(event) {
    event.preventDefault()
    const input = this.channelSecretTarget
    const isPassword = input.type === 'password'
    input.type = isPassword ? 'text' : 'password'

    // Button text handled by healthicon in HTML
  }

  // Validate LINE credentials
  async validate(event) {
    event.preventDefault()

    const channelId = this.channelIdTarget.value
    const channelSecret = this.channelSecretTarget.value

    if (!channelId || !channelSecret) {
      this.showStatus('請填寫 Channel ID 和 Channel Secret', 'error')
      return
    }

    // Show loading state
    this.showStatus('正在驗證憑證...', 'loading')
    this.validateBtnTarget.disabled = true

    try {
      const response = await fetch(this.validatePathValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCsrfToken()
        },
        body: JSON.stringify({
          line_channel_id: channelId,
          line_channel_secret: channelSecret
        })
      })

      const data = await response.json()

      if (data.success) {
        this.showStatus('憑證驗證成功！', 'success')
        this.validatedValue = true
        if (this.hasSaveBtnTarget) {
          this.saveBtnTarget.disabled = false
        }
      } else {
        this.showStatus(data.message || '驗證失敗', 'error')
        this.validatedValue = false
        if (this.hasSaveBtnTarget) {
          this.saveBtnTarget.disabled = true
        }
      }
    } catch (error) {
      this.showStatus('網路錯誤：' + error.message, 'error')
      this.validatedValue = false
      if (this.hasSaveBtnTarget) {
        this.saveBtnTarget.disabled = true
      }
    } finally {
      this.validateBtnTarget.disabled = false
    }
  }

  // Handle form submission
  submit(event) {
    if (!this.validatedValue) {
      event.preventDefault()
      this.showStatus('請先驗證憑證', 'error')
      return
    }
  }

  // Test existing connection
  async test(event) {
    event.preventDefault()

    const button = this.testBtnTarget
    button.disabled = true
    const originalText = button.textContent
    button.textContent = '測試中...'

    try {
      const response = await fetch(this.testPathValue, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.getCsrfToken()
        }
      })

      const data = await response.json()
      this.showTestModal(data)
    } catch (error) {
      this.showStatus('錯誤：' + error.message, 'error')
    } finally {
      button.disabled = false
      button.textContent = originalText
    }
  }

  // Clear configuration
  clear(event) {
    event.preventDefault()
    this.showConfirmModal()
  }

  // Helper: Show status message
  showStatus(message, type = 'info') {
    const statusDiv = this.validationStatusTarget

    // Clear any existing content first
    statusDiv.innerHTML = ''

    // Show the div
    statusDiv.classList.remove('hidden')

    let bgClass = 'bg-blue-50'
    let borderClass = 'border-blue-200'
    let textClass = 'text-blue-900'
    let iconHtml = ''  // Will use healthicons instead

    switch(type) {
      case 'success':
        bgClass = 'bg-green-50'
        borderClass = 'border-green-200'
        textClass = 'text-green-900'
        iconHtml = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>'
        break
      case 'error':
        bgClass = 'bg-red-50'
        borderClass = 'border-red-200'
        textClass = 'text-red-900'
        iconHtml = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>'
        break
      case 'loading':
        bgClass = 'bg-blue-50'
        borderClass = 'border-blue-200'
        textClass = 'text-blue-900'
        iconHtml = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="animate-spin"><path d="M12 2v4m0 12v4m8-8h-4m-12 0H2m15.364 6.364l-2.828-2.828M9.464 9.464L6.636 6.636m12.728 0l-2.828 2.828M9.464 14.536l-2.828 2.828"/></svg>'
        break
    }

    // Replace entire content (not append)
    statusDiv.innerHTML = `
      <div class="${bgClass} border ${borderClass} rounded-lg p-3 flex items-start space-x-2">
        <span class="flex-shrink-0 ${textClass}">${iconHtml}</span>
        <div class="flex-1">
          <p class="text-xs ${textClass} font-medium">${message}</p>
        </div>
      </div>
    `
  }

  // Helper: Clear status message
  clearStatus() {
    if (this.hasValidationStatusTarget) {
      this.validationStatusTarget.innerHTML = ''
      this.validationStatusTarget.classList.add('hidden')
    }
  }

  // Helper: Show test result modal
  showTestModal(data) {
    // Remove any existing modal first
    this.removeModal('test-modal')

    const modalHtml = `
      <div id="test-modal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg shadow-xl max-w-sm w-full mx-4">
          <div class="border-b border-gray-200 px-6 py-4">
            <h3 class="text-lg font-bold text-gray-900">${data.success ? '連線成功' : '連線失敗'}</h3>
          </div>
          <div class="px-6 py-4">
            <p class="text-sm text-gray-700 mb-2">${data.success ? '連線測試成功！' : '連線測試失敗'}</p>
            <p class="text-xs text-gray-500">${data.success ? '最後驗證：' + data.last_validated : data.message}</p>
          </div>
          <div class="border-t border-gray-200 px-6 py-3 flex justify-end">
            <button data-action="click->setup#closeModal" data-modal-id="test-modal" class="px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700">確定</button>
          </div>
        </div>
      </div>
    `

    document.body.insertAdjacentHTML('beforeend', modalHtml)
  }

  // Helper: Show confirm modal for clearing
  showConfirmModal() {
    // Remove any existing modal first
    this.removeModal('confirm-modal')

    const confirmHtml = `
      <div id="confirm-modal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-white rounded-lg shadow-xl max-w-sm w-full mx-4">
          <div class="border-b border-gray-200 px-6 py-4">
            <h3 class="text-lg font-bold text-gray-900">確認重新設定</h3>
          </div>
          <div class="px-6 py-4">
            <p class="text-sm text-gray-700">您確定要清除設定嗎？您將需要重新設定。</p>
          </div>
          <div class="border-t border-gray-200 px-6 py-3 flex justify-end gap-2">
            <button data-action="click->setup#closeModal" data-modal-id="confirm-modal" class="px-4 py-2 bg-gray-300 text-gray-900 rounded-lg font-medium hover:bg-gray-400">取消</button>
            <button data-action="click->setup#confirmClear" class="px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700">確認清除</button>
          </div>
        </div>
      </div>
    `

    document.body.insertAdjacentHTML('beforeend', confirmHtml)
  }

  // Action: Close modal
  closeModal(event) {
    const modalId = event.currentTarget.dataset.modalId
    this.removeModal(modalId)
  }

  // Action: Confirm clear
  confirmClear() {
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.clearPathValue
    form.innerHTML = `
      <input type="hidden" name="_method" value="DELETE" />
      <input type="hidden" name="authenticity_token" value="${this.getCsrfToken()}" />
    `
    document.body.appendChild(form)
    form.submit()
  }

  // Helper: Remove modal by id
  removeModal(modalId) {
    const modal = document.getElementById(modalId)
    if (modal) modal.remove()
  }

  // Helper: Get CSRF token
  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}