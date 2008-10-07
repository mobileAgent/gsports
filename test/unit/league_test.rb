require 'test_helper'

class LeagueTest < ActiveSupport::TestCase
  
  fixtures :users, :leagues

  def test_validity
    l = leagues(:one)
    assert l.valid?
  end

  def test_preserve_admin_league
    assert_raise ActiveRecord::ActiveRecordError do
      User.admin.first.league.destroy
    end
  end

  def test_destroy
    l = leagues(:two)
    assert_difference League, :count, -1 do
      l.destroy
    end
  end

  def test_destroy_cascade_users
    l = leagues(:two)
    league_id = l.id
    u = User.find_by_league_id l.id
    l.destroy
    u.reload
    assert_not_equal u.league_id, league_id, 'User league ID not updated after league destroyed'
  end

end
