require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/activemessaging/lib/activemessaging/test_helper'
require File.dirname(__FILE__) + '/../../app/processors/application'

class UpdateVideoStatusProcessorTest < Test::Unit::TestCase
  include ActiveMessaging::TestHelper

  fixtures :video_assets
  
  def setup
    @processor = UpdateVideoStatusProcessor.new
  end
  
  def teardown
    @processor = nil
  end  

  def test_update_video_status_processor
    vidavee = stub_everything
    vidavee.stubs(:login).returns("vidavee_login_token")
    Vidavee.stubs(:find).with(:first).returns(vidavee)
    @processor.on_message(video_assets(:one).id.to_s)
    assert video_assets(:one).video_status == 'ready'
  end
end
