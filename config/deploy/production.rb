set :application, "globalsports"
role :app, "69.20.120.50", :user=>"gsapps"
role :db, "69.20.120.50", :user=>"gsapps", :primary => true
role :web, "69.20.120.50", :user=>"gsapps"

set :deploy_to, "/var/apps/#{application}"
set :ruby_bin, "/usr/local/bin/ruby"
set :gem_home, "/usr/local/lib/ruby/gems/1.8"
set :httpd_path, "/usr/sbin/httpd"
set :web_port, 80
set :server_name, "globalsports.net"
set :environment, "production"
set :migrate_env, "production"

set :branch, "prod_branch"
set :repository_cache, "git_prod_branch"
