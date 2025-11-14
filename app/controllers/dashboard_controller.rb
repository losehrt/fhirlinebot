class DashboardController < ApplicationController
  skip_before_action :require_setup_completion  # Allow access without setup
  before_action :require_login
  # Flexy layout is inherited from ApplicationController

  def show
    # 準備示範數據
    @stats = {
      total_users: 1234,
      active_sessions: 89,
      appointments: 56,
      messages: 234
    }

    @recent_activities = [
      { icon_category: 'people', icon_name: 'person', title: '新用戶註冊', description: 'John Doe 完成註冊', time: '5 分鐘前', type: 'green' },
      { icon_category: 'objects', icon_name: 'calendar', title: '預約掛號', description: '預約心臟科門診', time: '10 分鐘前', type: 'blue' },
      { icon_category: 'medications', icon_name: 'medicines', title: '用藥提醒', description: '已確認服用藥物', time: '30 分鐘前', type: 'green' },
      { icon_category: 'diagnostics', icon_name: 'results', title: '健康報告', description: '新的檢查報告已上傳', time: '1 小時前', type: 'blue' }
    ]
  end
end
