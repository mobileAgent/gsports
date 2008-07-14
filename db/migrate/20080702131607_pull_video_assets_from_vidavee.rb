class PullVideoAssetsFromVidavee < ActiveRecord::Migration
  def self.up

    # Just get a few of them here, see the utility
    # method referenced to get them all
    Vidavee.load_backend_video(50)
  end

  def self.down
    VideoAsset.find(:all).each { |v| v.destroy }
  end
end
