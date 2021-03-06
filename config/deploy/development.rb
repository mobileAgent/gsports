role :app, "localhost", :user => ENV['USER']
role :db, "localhost", :user => ENV['USER']
role :web, "localhost", :user => ENV['USER']
set :deploy_to, "/usr/local/#{application}"
set :ruby_bin, "/usr/local/bin/ruby"
set :gem_home, "/usr/local/lib/ruby/gems/1.8"
set :httpd_path, "/usr/sbin/httpd"
set :web_port, 80
set :environment, "development"
set :branch, "master"
