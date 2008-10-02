# gem install capistrano-ext for this one
require 'capistrano/ext/multistage'

set :stages, %w(development testing qa production) 

set :application, "gsports"
set :repository,  "git@github.com:mobileAgent/gsports.git"
set :scm, 'git'
set :branch, "master"
set :repository_cache, "git_master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :scm_verbose, true

set :user, ENV["USER"]

set :rails_env, "development"
set :use_sudo, false

set :file_size_limit, 2684354560
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/id_rsa"]

set :log_level, :trace
set :group, "admin"
set :use_sudo, false
set :ssh_options, { :forward_agent => true }

set :app_symlinks, %w(files photos assets)
set :rails_config_files, %w(database.yml mailer.yml application.yml lucifer.yml broker.yml)

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

  desc "Do sphinx stuff on new app"
  task :after_update_code do
    migrate
    sphinx.restart
    create_symlinks
    poller.restart_poller
    memcached.clear
    update_configuration
  end

  desc "Migration is broken in recipe.rb line 341, try fixing it here"
  task :migrate, :roles => :db, :only => { :primary => true } do 
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "development")
    migrate_env = fetch(:migrate_env, "")
    migrate_target = fetch(:migrate_target, :latest)
 
    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest then current_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end
 
    run "cd #{directory}; #{rake} RAILS_ENV=#{migrate_env} db:migrate"
  end 
  
end

namespace :memcached do
  desc "Clear the cache"
  task :clear do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:environment, "development")
    run "cd #{current_release}; RAILS_ENV=#{rails_env} #{rake} gsports:clear_cache"
  end
end

namespace :poller do
  
  desc "Restart our poller"
  task :restart_poller do
    stop_prior_poller
    start_poller
  end

  desc "stop previous poller"
  task :stop_prior_poller, :roles=>:app do
    if previous_release
      rails_env = fetch(:environment, "development")
      run "cd #{previous_release}; RAILS_ENV=#{rails_env} script/poller stop"
    end
  end
  
  desc "start poller"
  task :start_poller, :roles=>:app do
    rails_env = fetch(:environment, "development")
    run "cd #{current_release}; RAILS_ENV=#{rails_env} script/poller start"
  end
end

desc "Update the configuration"
task :update_configuration, :roles => :app do
  rails_env = fetch(:environment, "development")
  set (:billing_gateway_password) do
    Capistrano::CLI.ui.ask "Enter billing gateway password: "
  end
  configuration_path = "#{current_release}/config/environments/#{rails_env}.rb"
  get configuration_path, "/tmp/#{rails_env}.rb"
  str = File.new("/tmp/#{rails_env}.rb").read
  str.gsub!('INSERT-BILLING-GATEWAY-PASSWORD',billing_gateway_password)
  put str, configuration_path
end

desc "Symlink in the shared stuff"
task :create_symlinks do
  as = fetch(:runner, "app")
  via = fetch(:run_method, :run)
  base_dir = fetch(:deploy_to)
  invoke_command("cd #{current_release} && ln -s #{base_dir}/shared/photos ./public/photos", :via => via, :as => as)        
  # invoke_command("cd #{current_release} && ln -s #{base_dir}/shared/videos ./public/videos", :via => via, :as => as)        
end

namespace :sphinx do
  desc "Restart sphinx"
  task :restart do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:environment, "development")
    begin
      run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} thinking_sphinx:stop"
    rescue
      puts "sphinx was not running, ok."
    end
    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} thinking_sphinx:configure"
    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} thinking_sphinx:index"
    run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} thinking_sphinx:start"
  end
end

