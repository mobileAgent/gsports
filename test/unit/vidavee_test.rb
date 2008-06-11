require 'test_helper'

class VidaveeTest < ActiveSupport::TestCase
  
  # There always has to be one record or the system will not function
  def test_one_record_exists
    assert Vidavee.find(:first)
  end

end
