class AddStaffRoles < ActiveRecord::Migration
  def self.up
    Role.enumeration_model_updates_permitted = true
    Role.create(:name => 'team_staff')
    Role.create(:name => 'league_staff')
    Role.create(:name => 'scout_staff')
  end

  def self.down
    Role.enumeration_model_updates_permitted = true
    Role[:team_staff].destroy()
    Role[:league_staff].destroy()
    Role[:scout_staff].destroy()
  end
end
