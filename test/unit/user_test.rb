require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  fixtures :users, :roles, :subscription_plans, :teams, :leagues
  
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

  def test_league_staff_relationship_not_through_team
    u = users(:kyle)
    assert(u.league_name == leagues(:two).name)
    assert(u.team_name == teams(:one).name)
  end

  def test_delegation_methods_setup_properly
    u = users(:kyle)
    assert_not_nil u.team_id
    assert_not_nil u.league_id
    assert_not_nil u.team
    assert_not_nil u.league
    assert_not_nil u.avatar
    assert_not_nil u.team_avatar
    assert_not_nil u.league_avatar
    assert_not_nil u.team_name
    assert_not_nil u.league_name
    assert_not_nil u.team.league_name
  end

  def test_metro_area_validation_turned_off
    u = users(:gsports_admin)
    u.metro_area_id=nil
    u.state = states(:maryland)
    u.password= "testpass"
    u.password_confirmation= "testpass"
    assert(u.save!)
  end

end
