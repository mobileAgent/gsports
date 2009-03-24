class AddAutoPlayToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :autoplay, :boolean
  end

  def self.down
    remove_column :channels, :autoplay
  end
end
