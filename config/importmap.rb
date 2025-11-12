# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Rails Block dependencies - 本地化管理
# 使用 vendor/javascript 目錄存放第三方庫
pin_all_from "vendor/javascript", under: "vendor"

# Floating UI - 用於下拉選單和彈出框
pin "@floating-ui/dom", to: "vendor/floating-ui-dom.js"
pin "@floating-ui/core", to: "vendor/floating-ui-core.js"
pin "@floating-ui/utils", to: "vendor/floating-ui-utils.js"
pin "@floating-ui/utils/dom", to: "vendor/floating-ui-utils-dom.js"
