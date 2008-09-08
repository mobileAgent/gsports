namespace :gsports do

  desc "Clear memcached"
  task :clear_cache => :environment do
    Rails.cache.clear
  end 

end