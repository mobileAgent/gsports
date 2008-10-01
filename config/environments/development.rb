# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# Configuration for community engine
APP_URL = "http://localhost:3000"

# Caching, memcache on localhost for development
config.cache_store = :mem_cache_store

# THis thing is unbelievably noisy and log cluttering

# Billing values - INSERT-BILLING-GATEWAY-PASSWORD replaced with value
ActiveMerchant::Billing::Base.mode = :test
Active_Merchant_payflow_gateway_username = 'markdr'
Active_Merchant_payflow_gateway_password = 'MarkDR1'
Active_Merchant_payflow_gateway_partner = 'PayPal'

PAYMENT_DUE_CYCLE = 30 # How often to bill in days

AD_SERVER_BASE = 'www.danmcardle.com/openx/www/delivery'
AD_ZONE_N = ['','a04a93c3','a4e788a7','a03c6fbc','a6e6602c','a6d175df']

CLOSED_BETA_MODE = false
ALLOWED_IP_ADDRS = ['127.0.0.1']
