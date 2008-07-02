class PullVideoAssetsFromVidavee < ActiveRecord::Migration
  def self.up
    v = Vidavee.find(:first)
    token = v.login
    save_count = v.load_gallery_assets token
    puts "Pulled and saved #{save_count} video assets from Vidavee"
  end

  def self.down
    VideoAsset.find(:all).each { |v| v.delete! }
  end
end
