require 'vendor/plugins/community_engine/app/models/role'
class Role < ActiveRecord::Base
  TEAM_ROLE = "team"
  LEAGUE_ROLE = "league"
  SCOUT_ROLE = "scout"
  
  belongs_to :subscription_plan
  
  def plan
    SubscriptionPlan.find_by_name(name)
  end
end