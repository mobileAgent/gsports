class AddDockeyToReport < ActiveRecord::Migration
  def self.up
    add_column :reports, :dockey, :string
    remove_column :reports, :access_group_id
  end

  def self.down
    add_column :reports, :access_group_id, :integer
    remove_column :reports, :dockey
  end
end
