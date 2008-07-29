require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  fixtures :users, :roles, :subscription_plans
  
  # Test the creation of a GSports team manager
  def test_create_team_manager
    buser = User.find_by_login "mark"
    assert_not_nil buser
    assert buser.team_admin?
    assert !buser.league_admin?
    assert !buser.scout_admin?
  end

  def test_league_staff
    u = users(:kyle)
    assert u.league_staff?
  end
  
end
