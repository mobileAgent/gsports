class AddDimToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :height, :integer
    add_column :channels, :width, :integer
    add_column :channels, :thumb_height, :integer
    add_column :channels, :thumb_width, :integer
    add_column :channels, :thumb_count, :integer
  end

  def self.down
    remove_column :channels, :height
    remove_column :channels, :width
    remove_column :channels, :thumb_height
    remove_column :channels, :thumb_width
    remove_column :channels, :thumb_count
  end
end
