require 'vendor/plugins/community_engine/app/models/role'
class Role < ActiveRecord::Base
  TEAM_ROLE = "team"
  LEAGUE_ROLE = "league"
  SCOUT_ROLE = "scout"
  MEMBER_ROLE = "member"
  
  belongs_to :subscription_plan
  
  def plan
    SubscriptionPlan.find_by_name(name)
  end

  def self.non_billable_role_ids
    [ Role[:admin].id, Role[:league_staff].id,
      Role[:team_staff].id, Role[:scout_staff].id ]
  end
  
end
