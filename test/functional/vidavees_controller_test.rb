require 'test_helper'

class VidaveesControllerTest < ActionController::TestCase

  fixtures :vidavees, :users, :roles

  def setup
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_index
    login_as :admin
    get :index
    assert_response :success
  end

end
