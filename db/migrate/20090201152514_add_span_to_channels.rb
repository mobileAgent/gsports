class AddSpanToChannels < ActiveRecord::Migration
  def self.up
      add_column :channels, :thumb_span, :integer
  end

  def self.down
    remove_column :channels, :thumb_span
  end
end
