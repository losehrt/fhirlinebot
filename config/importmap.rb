# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Note: Vendor libraries (Floating UI, Embla Carousel) are available in vendor/javascript
# but are not pinned here since they're not currently used in the application.
# Add pins below only when these libraries are actually used in views/controllers.
