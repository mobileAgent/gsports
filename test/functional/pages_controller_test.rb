require File.dirname(__FILE__) + '/../test_helper'
require 'pages_controller'

# Re-raise errors caught by the controller.
class PagesController; def rescue_action(e) raise e end; end

class PagesControllerTest < ActionController::TestCase

  fixtures :pages

  def setup
    @controller = PagesController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_show_by_permalink
    get :show, :permalink => pages(:one).permalink
    assert_response :success
  end

  def test_show_by_id
    get :show, :id => pages(:two).id
    assert_response :success
  end

  def test_permalink_not_found
    begin
      get :show, :permalink => 'foo'
      assert_response :missing
    rescue
    end
  end
end
