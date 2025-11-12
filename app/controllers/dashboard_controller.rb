class DashboardController < ApplicationController
  # Flexy layout is inherited from ApplicationController

  def index
    # 準備示範數據
    @stats = {
      total_users: 1234,
      active_sessions: 89,
      appointments: 56,
      messages: 234
    }

    @recent_activities = [
      { icon: '👤', title: '新用戶註冊', description: 'John Doe 完成註冊', time: '5 分鐘前', type: 'green' },
      { icon: '📅', title: '預約掛號', description: '預約心臟科門診', time: '10 分鐘前', type: 'blue' },
      { icon: '💊', title: '用藥提醒', description: '已確認服用藥物', time: '30 分鐘前', type: 'green' },
      { icon: '📋', title: '健康報告', description: '新的檢查報告已上傳', time: '1 小時前', type: 'blue' }
    ]
  end
end
