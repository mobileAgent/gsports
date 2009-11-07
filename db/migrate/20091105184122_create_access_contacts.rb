class CreateAccessContacts < ActiveRecord::Migration

  def self.up
    create_table :access_contacts do |t|
      t.integer  :access_group_id
      t.string   :contact_type, :limit=>3
      t.string   :destination
    end
  end

  def self.down
    drop_table :access_contacts
  end

end
