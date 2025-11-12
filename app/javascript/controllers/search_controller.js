import { Controller } from "@hotwired/stimulus"

// Flexy Search Controller
export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    url: { type: String, default: "/search" }
  }

  connect() {
    this.timeout = null
  }

  query(event) {
    const query = event.target.value.trim()

    // 清除之前的 timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // 如果查詢為空，隱藏結果
    if (query.length === 0) {
      this.hideResults()
      return
    }

    // Debounce - 等待 300ms 後才執行搜尋
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      // 顯示載入狀態
      this.showLoading()

      // 發送搜尋請求
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error('Search failed')
      }

      const data = await response.json()
      this.displayResults(data)

    } catch (error) {
      console.error('Search error:', error)
      this.showError()
    }
  }

  displayResults(data) {
    if (!this.hasResultsTarget) {
      this.createResultsContainer()
    }

    // 如果沒有結果
    if (!data || data.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="search-no-results">
          <p>找不到相關結果</p>
        </div>
      `
      this.showResults()
      return
    }

    // 顯示搜尋結果
    const resultsHTML = data.map(item => `
      <a href="${item.url}" class="search-result-item">
        <div class="result-icon">${item.icon || '📄'}</div>
        <div class="result-content">
          <div class="result-title">${item.title}</div>
          <div class="result-description">${item.description || ''}</div>
        </div>
      </a>
    `).join('')

    this.resultsTarget.innerHTML = resultsHTML
    this.showResults()
  }

  createResultsContainer() {
    const container = document.createElement('div')
    container.className = 'search-results hidden'
    container.setAttribute('data-search-target', 'results')
    this.inputTarget.parentElement.appendChild(container)
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove('hidden')
    }
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add('hidden')
    }
  }

  showLoading() {
    if (!this.hasResultsTarget) {
      this.createResultsContainer()
    }

    this.resultsTarget.innerHTML = `
      <div class="search-loading">
        <div class="loading-spinner"></div>
        <p>搜尋中...</p>
      </div>
    `
    this.showResults()
  }

  showError() {
    if (!this.hasResultsTarget) {
      this.createResultsContainer()
    }

    this.resultsTarget.innerHTML = `
      <div class="search-error">
        <p>搜尋發生錯誤，請稍後再試</p>
      </div>
    `
    this.showResults()
  }

  // 點擊外部時隱藏搜尋結果
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}