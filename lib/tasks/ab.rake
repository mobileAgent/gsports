namespace :ab do

  desc "Restart this app in mod_rails"
  task :restart do
    puts "Restart this app in mod_rails"
    system "touch tmp/restart.txt"
  end
  
  
  desc "Update length on all videos without a valid length, seriously"
  task :test => :environment do

      puts "snarf"
    
    
  end
  

end
