require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users, :roles, :subscription_plans
  # Test the creation of a GSports Team member
  def test_create_team_member
    user_count = User.find :all
    puts "USER COUNT:" + user_count.length.to_s
    buser = User.find_by_login "mark"
    puts buser.inspect
    assert_not_nil buser
    assert buser.isTeam?
    assert !buser.isLeague?
    assert !buser.isScout?

#    assert buser.valid?
  end
end