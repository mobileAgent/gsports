require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  fixtures :users, :roles, :subscription_plans
  
  # Test the creation of a GSports team manager
  def test_create_team_manager
    buser = User.find_by_login "mark"
    assert_not_nil buser
    assert buser.isTeamRole?
    assert !buser.isLeagueRole?
    assert !buser.isScoutRole?
  end
end
