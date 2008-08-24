role :app, "gsports.integratedcc.com"
set :deploy_to, "/usr/local/#{application}"
set :ruby_bin, "/usr/bin/ruby"
set :gem_home, "/usr/lib/ruby/gems/1.8"
set :httpd_path, "/usr/sbin/httpd"
set :web_port, 80
set :environment, "qa"
