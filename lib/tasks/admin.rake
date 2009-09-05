namespace :mod do

  desc "Restart this app in mod_rails"
  task :restart do
    puts "Restart this app in mod_rails"
    system "touch tmp/restart.txt"
  end

  desc "Restart this app in mod_rails"
  task :r do
    puts "Restart this app in mod_rails"
    system "touch tmp/restart.txt"
  end

end
