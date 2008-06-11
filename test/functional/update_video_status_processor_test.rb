require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/activemessaging/lib/activemessaging/test_helper'
require File.dirname(__FILE__) + '/../../app/processors/application'

class UpdateVideoStatusProcessorTest < Test::Unit::TestCase
  include ActiveMessaging::TestHelper
  
  def setup
    @processor = UpdateVideoStatusProcessor.new
  end
  
  def teardown
    @processor = nil
  end  

  def test_update_video_status_processor
    @processor.on_message('Your test message here!')
  end
end