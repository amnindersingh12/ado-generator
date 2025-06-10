# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.precompile += %w[authentication.css]


Rails.application.config.assets.precompile += %w(
  bootstrap.min.css
  bootstrap-icons.css
  chart.min.js
  bootstrap.bundle.min.js
)

# If they are in a 'vendor' subdirectory (e.g., app/assets/stylesheets/vendor/):
Rails.application.config.assets.paths << Rails.root.join("app/assets/fonts")
Rails.application.config.assets.paths << Rails.root.join("node_modules")
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font/fonts") # If fonts are still being searched outside app/assets/fonts
