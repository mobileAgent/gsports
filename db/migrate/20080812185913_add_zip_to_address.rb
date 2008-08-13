class AddZipToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :zip, :string
    add_column :addresses, :addressable_id, :integer
    add_column :addresses, :addressable_type, :string
  end

  def self.down
    remove_column :addresses, :zip
    remove_column :addresses, :addressable_id
    remove_column :addresses, :addressable_type
  end
end
