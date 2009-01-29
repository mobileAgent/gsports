# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Configuration for community engine
APP_URL = "http://localhost:3000"

# Category for head post on team and league pages
ADMIN_TEAM_HEADER_CATEGORY = 1

# Caching, use memory for dev/test
config.cache_store = :memory_store

AD_SERVER_BASE = 'www.danmcardle.com/openx/www/delivery'
AD_ZONE_N = ['','a04a93c3','a4e788a7','a03c6fbc','a6e6602c','a6d175df']

# Billing values
ActiveMerchant::Billing::Base.mode = :test
Active_Merchant_payflow_gateway_username = 'markdr'
Active_Merchant_payflow_gateway_password = 'MarkDR1'
Active_Merchant_payflow_gateway_partner = 'PayPal'

PAYMENT_DUE_CYCLE = 10 # How often to bill in days

CLOSED_BETA_MODE = false
ALLOWED_IP_ADDRS = []

