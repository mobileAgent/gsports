class AddUrlToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :allow_url, :string
  end

  def self.down
    remove_column :channels, :allow_url
  end
end
