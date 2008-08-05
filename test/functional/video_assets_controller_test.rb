require File.dirname(__FILE__) + '/../test_helper'
require 'video_assets_controller'

# Re-raise errors caught by the controller.
class VideoAssetsController; def rescue_action(e) raise e end; end

class VideoAssetsControllerTest < ActionController::TestCase
  
  fixtures :users, :roles, :video_assets, :teams

  def setup
    @controller = VideoAssetsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end

  def test_should_get_index
    login_as :admin
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
  
  def test_should_create_video_asset_with_team_name
    login_as :admin
    assert_difference(VideoAsset,:count,1) do
      post :create, :video_asset => {:dockey => 'abc123def456', :title=> 'this is the title', :description => 'this is the description', :team_name => teams(:two).name, :league_name => leagues(:one).name, :home_team_name => teams(:one).name, :visiting_team_name => teams(:two).name }
    end
    
    assert_redirected_to video_asset_path(assigns(:video_asset))
    #assert_equal VideoAsset.find_by_dockey('abc123def456').team_id,teams(:two).id
  end

  def test_should_create_video_asset_but_ignore_team_name
    login_as :mark # not the admin
    assert_difference(VideoAsset,:count,1) do
      post :create, :video_asset => {:dockey => '9988abc123def456', :title=> 'this is the title', :description => 'this is the description', :team_name => teams(:two).name }
    end
    
    assert_redirected_to video_asset_path(assigns(:video_asset))
    #assert_equal VideoAsset.find_by_dockey('9988abc123def456').team_id,teams(:one).id 
  end
  
  
  def test_should_show_video_asset
    login_as :admin
    vidavee = stub_everything
    vidavee.stubs(:asset_embed_code).returns("<embed>foo</embed>")
    Vidavee.stubs(:find).with(:first).returns(vidavee)
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

  def test_update_tags
    login_as :admin
    tags = VideoAsset.find(video_assets(:one).id).tags.collect(&:name)
    put :update, :id => video_assets(:one).id, :video_asset => {}, :tag_list => "newdog bluedog #{tags.join(' ')}"
    assert_redirected_to video_asset_path(assigns(:video_asset))
    assert_equal(tags.size+2, VideoAsset.find(video_assets(:one).id).tags.size)
  end
    
    
end
