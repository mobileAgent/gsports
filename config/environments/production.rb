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

# Set the cookie domain so that logins work with or without 'www.'
# Down side of doing this is it causes the cookie to be sent
# for all asset host requests too.
#ActionController::Base.session_options[:session_domain] = 'globalsports.net'

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"
# But not over ssl, since we don't have certs for all the pages
ActionController::Base.asset_host = Proc.new { |source, request|
  if request.ssl?
    "#{request.protocol}#{request.host_with_port}"
  else
    "http://gs#{rand(4)}.globalsports.net"
  end
}

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Configuration for community engine
APP_URL = "http://globalsports.net"

# Caching, memcache on localhost for production
config.cache_store = :mem_cache_store
#ActionController::Base.cache_store = :mem_cache_store, "localhost"

# Billing values
# NOTE: Change these to GS real values
#ActiveMerchant::Billing::Base.mode = :production
#Active_Merchant_payflow_gateway_username = ''
#Active_Merchant_payflow_gateway_password = ''
#Active_Merchant_payflow_gateway_partner = ''
ActiveMerchant::Billing::Base.mode = :test
Active_Merchant_payflow_gateway_username = 'markdr'
Active_Merchant_payflow_gateway_password = 'MarkDR1'
Active_Merchant_payflow_gateway_partner = 'PayPal'

PAYMENT_DUE_CYCLE = 30 # How often to bill in days

CLOSED_BETA_MODE = true
ALLOWED_IP_ADDRS = ['96.244.114.172','68.45.217.123','72.81.234.188','12.180.53.61','74.236.197.211','67.87.134.150','72.68.112.76','68.191.57.23','75.195.92.78']

AD_SERVER_BASE = 'ads.globalsports.net'
