class CreatePpvAccesses < ActiveRecord::Migration
  def self.up
    create_table :ppv_accesses do |t|

      t.integer :user_id
      t.integer :video_id
      t.decimal :cost
      t.datetime :expires

      t.timestamps
    end
  end

  def self.down
    drop_table :ppv_accesses
  end
end
