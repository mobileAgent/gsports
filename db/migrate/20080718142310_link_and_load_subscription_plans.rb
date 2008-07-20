class LinkAndLoadSubscriptionPlans < ActiveRecord::Migration
  def self.up
    directory = File.join(File.dirname(__FILE__),"dev_data")
    Fixtures.create_fixtures(directory,"subscription_plans")
   
    Role.enumeration_model_updates_permitted = true
    Role.create(:name => Role::MEMBER_ROLE, :subscription_plan => SubscriptionPlan.find_by_name(Role::MEMBER_ROLE))
    Role.create(:name => Role::TEAM_ROLE, :subscription_plan => SubscriptionPlan.find_by_name(Role::TEAM_ROLE))
    Role.create(:name => Role::LEAGUE_ROLE, :subscription_plan => SubscriptionPlan.find_by_name(Role::LEAGUE_ROLE))
    Role.create(:name => Role::SCOUT_ROLE, :subscription_plan => SubscriptionPlan.find_by_name(Role::SCOUT_ROLE))
  end

  def self.down
  end
end
