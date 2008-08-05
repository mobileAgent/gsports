# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"
# ActionController::Base.asset_host = "http://assets%d.globalsports.net"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Configuration for community engine
APP_URL = "http://globalsports.net"

# Caching, memcache on localhost for production
config.cache_store = :mem_cache_store
#ActionController::Base.cache_store = :mem_cache_store, "localhost"

AD_SERVER_BASE = 'www.danmcardle.com/openx/www/delivery/ajs.php'
