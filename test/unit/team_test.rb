require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  
  fixtures :teams

  def test_validity
    t = teams(:one)
    assert t.valid?
  end

end
