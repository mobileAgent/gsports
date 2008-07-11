require 'test_helper'

class LeagueTest < ActiveSupport::TestCase
  
  fixtures :leagues

  def test_validity
    l = leagues(:one)
    assert l.valid?
  end

end
