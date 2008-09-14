require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  fixtures :video_assets, :video_clips, :video_reels
  
  def setup
    @controller = SearchController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_xml_for_clip
    login_as :kyle
    get :d, :dockey => video_clips(:one).dockey
    assert_response :success
  end
  
  def test_xml_for_reel
    login_as :kyle
    get :d, :dockey => video_reels(:one).dockey
    assert_response :success
  end
  
  def test_xml_for_asset
    login_as :kyle
    get :d, :dockey => video_assets(:one).dockey
    assert_response :success
  end

end
