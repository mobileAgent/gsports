namespace :vidavee do

  desc "Load or update all video assets from the vidavee backend"
  task :load_video_assets => :environment do
    Vidavee.load_backend_video
  end
  
  desc "Load or update all video clips (vtags) from the vidavee backend"
  task :load_video_clips => :environment do
    Vidavee.load_backend_clips
  end
  
  desc "Load or update all video reels (playlists) from the vidavee backend"
  task :load_video_reels => :environment do
    Vidavee.load_backend_reels
  end

  desc "Update the status of the specified video asset from the vidavee backend"
  task :update_video_asset_status => :environment do
    id = ENV['ID']
    if id.nil?
      puts "Specify ID=# on the command line"
      return
    end
    video_asset = VideoAsset.find(id)
    if video_asset.nil?
      puts "No video for id #{id}"
      return
    end
    vidavee = Vidavee.find(:first)
    login = vidavee.login
    if login.nil?
      puts "Cannot log into vidavee back end"
      return
    end
    vidavee.update_asset_record(login,video_asset)
    video_asset.save!
    puts "Status is #{video_asset.video_status}"
  end

  desc "Re-try to push the specified video_asset.id to the vidavee backend"
  task :push_video_file => :environment do
    id = ENV['ID']
    if id.nil?
      puts "Specify ID=# on the command line"
      return
    end
    video_asset = VideoAsset.find(ENV['ID'])
    if video_asset.nil?
      puts "Video asset not found for id #{id}"
      return
    end
    vidavee = Vidavee.find(:first)
    login = vidavee.login
    if login.nil?
      puts "Cannot log into vidavee back end"
      return
    end
    dockey = vidavee.push_video login, video_asset, video_asset.uploaded_file_path
    if dockey
      puts "Success dockey=#{dockey}"
    else
      puts "Failed"
    end
  end
  
end
