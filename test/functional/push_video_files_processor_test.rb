require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/activemessaging/lib/activemessaging/test_helper'
require File.dirname(__FILE__) + '/../../app/processors/application'

class PushVideoFilesProcessorTest < Test::Unit::TestCase
  include ActiveMessaging::TestHelper
  
  def setup
    @processor = PushVideoFilesProcessor.new
  end
  
  def teardown
    @processor = nil
  end  

  def test_push_video_files_processor
    @processor.on_message('Your test message here!')
  end
end