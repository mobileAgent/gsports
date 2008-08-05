require 'active_record/fixtures'

class CreateLeagues < ActiveRecord::Migration
  def self.up
    create_table :leagues do |t|
      t.string :name
      t.string :logo_uri
      t.string :city
      t.string :state
      t.string :description
      t.boolean :active

      t.timestamps 
    end

    execute "insert into leagues (name,logo_uri,city,state,description,active,created_at,updated_at) values ('Global Sports League','','Allover','Maryland','League for Global Sports Admin and Team',1,'#{Time.now.to_s :db}','#{Time.now.to_s :db}')"

  end

  def self.down
    drop_table :leagues
  end
end
