# gem install capistrano-ext for this one
require 'capistrano/ext/multistage'

set :stages, %w(development testing qa production) 
set :default_stage, 'development'

set :application, "gsports"
set :repository,  "git@github.com:mobileAgent/gsports.git"
set :scm, 'git'
set :branch, "master"
set :repository_cache, "git_master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :scm_verbose, true

set :user, ENV["USER"]

set :rails_env, "production"
set :use_sudo, false

set :file_size_limit, 2684354560
ssh_options[:keys] = ["#{ENV['HOME']}/.ssh/id_rsa"]

set :log_level, :trace
set :group, "admin"
set :use_sudo, false
set :ssh_options, { :forward_agent => true }

set :app_symlinks, %w(files photos videos assets)
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
    sphinx:configure
    create_symlinks
    poller:restart_poller
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
      as = fetch(:runner, "app")
      via = fetch(:run_method, :run)
      stage = fetch(:stage)    
      # need to be in RAILS_ROOT when this script is run
      invoke_command("cd #{previous_revision} && RAILS_ENV=#{stage} script/poller stop'", :via => via, :as => as)        
    end
  end
  
  desc "start poller"
  task :start_poller, :roles=>:app do
    as = fetch(:runner, "app")
    via = fetch(:run_method, :run)
    stage = fetch(:stage)    
    # need to be in RAILS_ROOT when this script is run
    invoke_command("cd #{current_path} && RAILS_ENV=#{stage} script/poller start'", :via => via, :as => as)        
  end
end

desc "Symlink in the shared stuff"
task :create_symlinks do
  as = fetch(:runner, "app")
  via = fetch(:run_method, :run)
  base_dir = fetch(:deploy_to)
  invoke_command("cd #{current_release} && ln -s #{base_dir}/shared/photos ./public/photos", :via => via, :as => as)        
  invoke_command("cd #{current_release} && ln -s #{base_dir}/shared/videos ./public/videos", :via => via, :as => as)        
end

namespace :sphinx do
  desc "Generate the ThinkingSphinx configuration file"
  task :configure do
    run "cd #{current_release} && rake thinking_sphinx:index"
    run "cd #{current_release} && rake thinking_sphinx:restart"
  end
end

