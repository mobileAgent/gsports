class PullVideoAssetsFromVidavee < ActiveRecord::Migration
  def self.up
    puts "Nah, this is a bad idea. See the rake task for doing it right."
    # Vidavee.load_backend_video(50)
  end

  def self.down
    VideoAsset.find(:all).each { |v| v.destroy }
  end
end
