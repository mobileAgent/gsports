require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  
  fixtures :users, :teams

  def test_validity
    t = teams(:one)
    assert t.valid?
  end

  def test_preserve_admin_team
    assert_raise ActiveRecord::ActiveRecordError do
      User.admin.first.team.destroy
    end
  end

  def test_destroy
    t = teams(:two)
    assert_difference Team, :count, -1 do
      t.destroy
    end
  end

  def test_destroy_cascade_users
    t = teams(:two)
    team_id = t.id
    u = User.find_by_team_id t.id
    t.destroy
    u.reload
    assert_not_equal u.team_id, team_id, 'User team ID not updated after team destroyed'
  end

end
