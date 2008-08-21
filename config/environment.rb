require 'yaml'

# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # To separate the different environments we load session keys
  # from database.yml, where other passwords live
  db = YAML.load_file("#{RAILS_ROOT}/config/database.yml")
  config.action_controller.session = {
     :session_key => db[RAILS_ENV]['session_key'],
     :secret      => db[RAILS_ENV]['secret']
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  
  # Make sure we get super red cloth
  config.gem "RedCloth", :version => ">= 4.0.3"
  config.gem "httpclient", :version => ">= 2.1.2"
  config.gem "hpricot", :version => ">= 0.6"
  config.gem "stomp" , :version => ">= 1.0.5"
  config.gem "reliable-msg", :version => ">= 1.1.0"
  #config.gem "rmagick", :version => ">= 2.5.1" # this blows up on fedora 9
  config.gem "rake", :version => ">= 0.8.1"
  config.gem "mocha", :version => ">= 0.9.0"
  config.gem "haml", :version => ">= 2.0.0"
  #config.gem "mime-types", :version => ">= 1.15" # this one fails for some reason
  config.gem "mysql", :version => "= 2.7"
  config.gem "uuid", :version => ">= 1.0.4"
  config.gem "will_paginate", :version => ">= 2.2.2"
  config.gem "htmlentities", :version => ">= 4.0.0"
  config.gem "ezcrypto", :version => "= 0.7"
  config.gem "daemons", :version => ">= 1.0.9"
  
  #resource_hacks required here to ensure routes like /:login_slug work
  config.plugins = [:engines, :community_engine, :white_list, :all]
  config.plugin_paths += ["#{RAILS_ROOT}/vendor/plugins/community_engine/engine_plugins"]

end


ExceptionNotifier.exception_recipients = %w(flester@gmail.com)

# Project requires go here, rather than spread out in the project
require "#{RAILS_ROOT}/vendor/plugins/community_engine/engine_config/boot.rb"
require 'digest/md5'
require 'activemessaging/processor'

# This sets the root of where video upload and 
# transfer to vidavee takes place. Best not to be
# under the public web server as we don't want to
# be serving these up ourselves.
VIDEO_BASE = "#{RAILS_ROOT}/videos"

# Email addr for the admin account
ADMIN_EMAIL = "admin@globalsports.net"

FOOTER_AD_COUNT = 3

