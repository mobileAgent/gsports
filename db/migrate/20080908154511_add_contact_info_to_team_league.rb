class AddContactInfoToTeamLeague < ActiveRecord::Migration
  def self.up
    add_column :teams, :address1, :string
    add_column :teams, :address2, :string
    add_column :teams, :phone, :string
    add_column :teams, :zip, :string
    add_column :teams, :email, :string
    
    add_column :leagues, :address1, :string
    add_column :leagues, :address2, :string
    add_column :leagues, :phone, :string
    add_column :leagues, :zip, :string
    add_column :leagues, :email, :string
  end

  def self.down
    remove_column :teams, :address1
    remove_column :teams, :address2
    remove_column :teams, :phone
    remove_column :teams, :zip
    remove_column :teams, :email
    
    remove_column :leagues, :address1
    remove_column :leagues, :address2
    remove_column :leagues, :phone
    remove_column :leagues, :zip
    remove_column :leagues, :email
  end
end
