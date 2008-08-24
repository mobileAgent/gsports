role :app, "69.20.120.50", :user=>"gsapps"
set :deploy_to, "/var/apps/#{application}"
set :ruby_bin, "/usr/local/bin/ruby"
set :gem_home, "/usr/local/lib/ruby/gems/1.8"
set :httpd_path, "/usr/sbin/httpd"
set :web_port, 80
set :server_name, "globalsports.net"
set :environment, "production"
set :runner, "root"

set :passenger_root, "/usr/local/lib/ruby/gems/1.8/gems/passenger-2.0.3"
set :passenger_mod, "/usr/local/lib/ruby/gems/1.8/gems/passenger-2.0.3/ext/apache2/mod_passenger.so"
set :do_not_generate_httpd_conf, true
set :apache_server_conf, "/etc/httpd/conf/httpd.conf"
set :httpd_path, "/usr/sbin/apachectl"
