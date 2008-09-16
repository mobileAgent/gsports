class CreateSorConfigs < ActiveRecord::Migration
  def self.up
    create_table :sor_configs do |t|
      t.integer :state_id, :null => false
      t.string :state_code, :null => false, :limit =>5
      t.string :state_name, :null => false, :limit =>5
      t.string :website, :null => false, :limit => 255
      t.boolean :is_check, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :sor_configs
  end
end
