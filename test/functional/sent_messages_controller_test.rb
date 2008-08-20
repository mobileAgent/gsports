require 'test_helper'

class SentMessagesControllerTest < ActionController::TestCase
  fixtures :users, :roles, :video_assets, :teams

  def setup
    @controller = VideoAssetsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_should_get_index
    login_as :kyle
    get :index
    assert_response :success
  end

  def test_should_show_sent_message
    login_as :kyle
    get :show, :id => sent_messages(:one).id
    assert_response :success
  end

#  def test_should_destroy_sent_message
#    login_as :kyle
#    assert_difference(SentMessage,:count, -1) do
#      delete :destroy, :id => sent_messages(:one).id
#    end
#
#    assert_redirected_to sent_messages_path
#  end
end
