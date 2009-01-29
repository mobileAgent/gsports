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
APP_URL = "http://gsports.integratedcc.com"

# Category for head post on team and league pages
ADMIN_TEAM_HEADER_CATEGORY = 7

# Caching, memcache on localhost for production
config.cache_store = :mem_cache_store
#ActionController::Base.cache_store = :mem_cache_store, "localhost"

# Billing values - INSERT-BILLING-GATEWAY-PASSWORD replaced with value
ActiveMerchant::Billing::Base.mode = :test
Active_Merchant_payflow_gateway_username = 'markdr'
Active_Merchant_payflow_gateway_password = 'MarkDR1'
Active_Merchant_payflow_gateway_partner = 'PayPal'

PAYMENT_DUE_CYCLE = 30 # How often to bill in days

CLOSED_BETA_MODE = false
ALLOWED_IP_ADDRS = []
ExceptionNotifier.email_prefix = '[GS-QA] '

AD_SERVER_BASE = 'www.danmcardle.com/openx/www/delivery'
AD_ZONE_N = ['a04a93c3','a4e788a7','a03c6fbc','a6e6602c','a6d175df']
