namespace :mod do

  desc "Restart this app in mod_rails"
  task :restart do
    puts "Restart this app in mod_rails"
    system "touch tmp/restart.txt"
    system("touch tmp/debug.txt") if ENV["DEBUG"] == 'true'
  end

  desc "Restart this app in mod_rails"
  task :r do
    puts "Restart this app in mod_rails"
    system "touch tmp/restart.txt"
    system("touch tmp/debug.txt") if ENV["DEBUG"] == 'true'
  end

  desc "Debug this app in mod_rails"
  task :d do
    puts "Restart this app in mod_rails DEBUGGING ON"
    system "touch tmp/restart.txt"
    system("touch tmp/debug.txt")
  end

end
