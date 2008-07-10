require File.dirname(__FILE__) + '/../test_helper'
require 'video_assets_controller'
require 'mocha'

# Re-raise errors caught by the controller.
class VideoAssetsController; def rescue_action(e) raise e end; end

class Vidavee
  CLIENT = stub(:post => '<xml>fake vidavee</xml>')
end

class VideoAssetsControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    puts "User id is #{users(:admin).id} which is cool"
    @controller = VideoAssetsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    #@request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:foo] = 'bar'
  end

  def test_should_get_index
    login_as :admin
    puts "Login as :admin produces #{@request.session[:user]}"
    get :index
    assert_response :success
    assert_not_nil assigns(:video_assets)
  end

  def test_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end

  def test_should_create_video_asset
    login_as :admin
    assert_difference(VideoAsset,:count,1) do
      post :create, :video_asset => {:dockey => 'abc123def456', :title=> 'this is the title', :description => 'this is the description' }
    end
    
    assert_redirected_to video_asset_path(assigns(:video_asset))
  end
  
  def test_should_show_video_asset
    login_as :admin
    get :show, :id => video_assets(:one).id
    assert_response :success
  end

  def test_should_get_edit
    login_as :admin
    get :edit, :id => video_assets(:one).id
    assert_response :success
  end

  def test_should_update_video_asset
    login_as :admin
    put :update, :id => video_assets(:one).id, :video_asset => { }
    assert_redirected_to video_asset_path(assigns(:video_asset))
  end

  def test_should_destroy_video_asset
    login_as :admin
    assert_difference(VideoAsset, :count, -1) do
      delete :destroy, :id => video_assets(:one).id
    end

    assert_redirected_to video_assets_path
  end
end
