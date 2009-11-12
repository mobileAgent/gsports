class AddTimestampsToReport < ActiveRecord::Migration
  def self.up
    add_column :reports, :created_at, :timestamp
    add_column :reports, :updated_at, :timestamp
  end

  def self.down
    remove_column :reports, :created_at
    remove_column :reports, :updated_at
  end
end
