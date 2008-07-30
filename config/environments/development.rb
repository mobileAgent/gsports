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

# Caching, use memory for dev/test
# config.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"
config.cache_store = :memory_store

# THis thing is unbelievably noisy and log cluttering

# Using ActiveMerchant in development
ActiveMerchant::Billing::Base.mode = :test
