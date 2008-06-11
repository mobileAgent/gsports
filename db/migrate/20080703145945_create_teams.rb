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
    team = Team.new
    team.name= 'Global Sports Home Team'
    team.city= 'Allover'
    team.state= 'State'
    team.description= 'Default team for the admin user'
    team.active= true
    team.league_id= League.find_by_name('Global Sports League').id
    team.save!
  end

  def self.down
    drop_table :teams
  end
end
