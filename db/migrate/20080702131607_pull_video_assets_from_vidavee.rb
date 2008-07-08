class PullVideoAssetsFromVidavee < ActiveRecord::Migration
  def self.up
    v = Vidavee.find(:first)
    token = v.login
    save_count = 0
    (1..10).each do |page|
      save_count +=
        v.load_gallery_assets token, 'rowsPerPage' => 50, 'AF_page' => page
    end
    puts "Pulled and saved #{save_count} video assets from Vidavee"
  end

  def self.down
    VideoAsset.find(:all).each { |v| v.destroy }
  end
end
