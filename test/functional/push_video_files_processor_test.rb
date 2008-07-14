require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/activemessaging/lib/activemessaging/test_helper'
require File.dirname(__FILE__) + '/../../app/processors/application'

class PushVideoFilesProcessorTest < Test::Unit::TestCase
  include ActiveMessaging::TestHelper
  
  fixtures :video_assets
  
  def setup
    @processor = PushVideoFilesProcessor.new
  end
  
  def teardown
    @processor = nil
  end  

  def test_push_video_files_processor
    vidavee = stub_everything
    vidavee.stubs(:login).returns("vidavee_login_token")
    Vidavee.stubs(:find).with(:first).returns(vidavee)
    @processor.on_message(video_assets(:one))
  end
end
