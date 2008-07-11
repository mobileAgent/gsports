require 'test_helper'

class StaticControllerTest < ActionController::TestCase

  def setup
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_get_tos
    get :tos
    assert_response :success
  end

  def test_get_faq
    get :faq
    assert_response :success
  end

  def test_get_contact
    get :contact
    assert_response :success
  end

  def test_get_privacy
    get :privacy
    assert_response :success
  end

  def test_get_welcome
    get :welcome
    assert_response :success
  end
  
end
