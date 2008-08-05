require 'active_record/fixtures'

class CreateTeams < ActiveRecord::Migration
  def self.up
    create_table :teams do |t|
      t.string :name
      t.string :logo_uri
      t.string :city
      t.string :state
      t.string :description
      t.boolean :active
      t.integer :league_id

      t.timestamps 
    end
    execute "insert into teams (name,logo_uri,city,state,description,active,league_id,created_at,updated_at) values ('Global Sports Home Team','','Allover','Maryland','Default Team for the Admin User',1,(select id from leagues limit 1),'#{Time.now.to_s :db}','#{Time.now.to_s :db}')"
  end

  def self.down
    drop_table :teams
  end
end
