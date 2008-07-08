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
    league = League.new
    league.name= 'Global Sports League'
    league.city= 'Allover'
    league.state= 'State'
    league.description= 'League for Global Sports Admin and Team'
    league.active= true
    league.save!
  end

  def self.down
    drop_table :leagues
  end
end
