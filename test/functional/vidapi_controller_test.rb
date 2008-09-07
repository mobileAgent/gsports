require 'test_helper'
require 'vidapi_controller'

# Re-raise errors caught by the controller.
class VidapiController; def rescue_action(e) raise e end; end

class VidapiControllerTest < ActionController::TestCase

  fixtures :users, :roles

  def setup
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_logout
    vidavee = stub_everything
    vidavee.stubs(:logout).returns(true)
    Rails.cache.stubs(:fetch).with('vidavee').returns(vidavee)
    Rails.cache.stubs(:fetch).with('quickfind_seasons').returns([]);
    Rails.cache.stubs(:fetch).with('quickfind_states').returns([]);
    Rails.cache.stubs(:fetch).with('quickfind_counties').returns([]);
    Rails.cache.stubs(:fetch).with('quickfind_leagues').returns([]);
    Rails.cache.stubs(:fetch).with('quickfind_sports').returns([]);
    Rails.cache.stubs(:fetch).with('quickfind_cities').returns([]);
    get :logout
    assert @request.session[:vidavee].nil?
  end

end
