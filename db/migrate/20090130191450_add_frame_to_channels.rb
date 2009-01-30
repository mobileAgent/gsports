class AddFrameToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :frame_height, :integer
    add_column :channels, :frame_width, :integer
  end

  def self.down
    remove_column :channels, :frame_height
    remove_column :channels, :frame_width
  end
end
