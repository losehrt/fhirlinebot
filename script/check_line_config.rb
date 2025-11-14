#!/usr/bin/env ruby

def check_env_variable(key, required: true)
  value = ENV[key]
  status = !value.nil? && !value.empty? ? "✓" : "✗"

  if ARGV.include?('--verbose') || value.nil? || value.empty?
    puts "#{status} #{key}: #{!value.nil? && !value.empty? ? value : '(未設置)'}"
  end

  !value.nil? && !value.empty? || !required
end

def check_https(url)
  url.start_with?('https://') ? "✓" : "✗"
end

puts "\n=== LINE Login 環境配置檢查 ===\n"

# Check required environment variables
puts "1. 環境變數檢查:"
all_good = true

channel_id = check_env_variable('LINE_LOGIN_CHANNEL_ID')
all_good = false unless channel_id

channel_secret = check_env_variable('LINE_LOGIN_CHANNEL_SECRET')
all_good = false unless channel_secret

redirect_uri = ENV['LINE_LOGIN_REDIRECT_URI']
if !redirect_uri.nil? && !redirect_uri.empty?
  https_ok = redirect_uri.start_with?('https://')
  puts "#{https_ok ? '✓' : '✗'} LINE_LOGIN_REDIRECT_URI: #{redirect_uri}"
  puts "  ⚠ 提醒: 使用 #{https_ok ? 'HTTPS' : 'HTTP'}" unless https_ok
else
  puts "✗ LINE_LOGIN_REDIRECT_URI: (未設置)"
  all_good = false
end

app_url = ENV['APP_URL']
if !app_url.nil? && !app_url.empty?
  https_ok = app_url.start_with?('https://')
  puts "#{https_ok ? '✓' : '✗'} APP_URL: #{app_url}"
  puts "  ⚠ 提醒: 使用 #{https_ok ? 'HTTPS' : 'HTTP'}" unless https_ok
else
  puts "✓ APP_URL: (未設置，使用默認值)"
end

# Display summary
puts "\n" + "="*40
if all_good
  puts "✓ 所有檢查通過！"
  puts "\n下一步:"
  puts "1. 確認 LINE_LOGIN_CHANNEL_ID 和 SECRET 是正確的"
  puts "2. 確認 LINE_LOGIN_REDIRECT_URI 與 LINE Developers Console 中的設置相匹配"
  puts "3. 訪問 https://ng.turbos.tw/auth/login 開始測試"
else
  puts "✗ 發現配置問題，請修復以上項目"
  exit 1
end

puts "="*40 + "\n"
