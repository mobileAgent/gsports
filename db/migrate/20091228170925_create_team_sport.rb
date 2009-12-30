class CreateTeamSport < ActiveRecord::Migration

   def self.up

    create_table :team_sports do |t|
      t.string   :name
      t.integer  :team_id
      t.integer  :access_group_id
      t.string   :description
      
      t.timestamps
    end

  end

  def self.down
    drop_table :team_sports
  end


end
