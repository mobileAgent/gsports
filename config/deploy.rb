set :application, "gsports"

# Set up for github
default_run_options[:pty] = true
set :repository,  "git@github.com:mobileAgent/gsports.git"
set :scm, "git"
#set :scm_passphrase, "copilot" #This is your custom users password
set :user, "mjflest"
set :branch, "master"
set :deploy_via, :remote_cache
set :git_shallow_clone, 1
set :scm_verbose, true

set :repository,  "set your repository location here"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/usr/local/gsports"

role :app, "gsports.integratedcc.com"
role :web, "gsports.integratedcc.com"
role :db,  "gsports.integratedcc.com", :primary => true

namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end

end

namespace :sphinx do
  desc "Generate the ThinkingSphinx configuration file"
  task :configure do
    run "cd #{deploy_to} && rake thinking_sphinx:configure"
    run "cd #{deploy_to} && rake thinking_sphinx:restart"
  end
end

after "deploy:update_code", "sphinx:configure"
