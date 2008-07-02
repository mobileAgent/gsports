require 'test_helper'

class VideoAssetsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:video_assets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_video_asset
    assert_difference('VideoAsset.count') do
      post :create, :video_asset => { }
    end

    assert_redirected_to video_asset_path(assigns(:video_asset))
  end

  def test_should_show_video_asset
    get :show, :id => video_assets(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => video_assets(:one).id
    assert_response :success
  end

  def test_should_update_video_asset
    put :update, :id => video_assets(:one).id, :video_asset => { }
    assert_redirected_to video_asset_path(assigns(:video_asset))
  end

  def test_should_destroy_video_asset
    assert_difference('VideoAsset.count', -1) do
      delete :destroy, :id => video_assets(:one).id
    end

    assert_redirected_to video_assets_path
  end
end
