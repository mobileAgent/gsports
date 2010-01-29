class CreateRosterEntries < ActiveRecord::Migration
  def self.up
    create_table :roster_entries do |t|

      t.integer :access_group_id

      t.string :number
      t.string :firstname
      t.string :lastname
      t.string :email
      t.string :phone
      t.string :position

      t.timestamps
    end
  end

  def self.down
    drop_table :roster_entries
  end
end

