require File.dirname(__FILE__) + '/../test_helper'
require 'video_clips_controller'

# Re-raise errors caught by the controller.
class VideoClipsController; def rescue_action(e) raise e end; end

class VideoClipsControllerTest < ActionController::TestCase

  fixtures :video_assets, :video_clips, :users, :roles

  def setup
    @controller = VideoClipsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_should_get_index
    login_as :quentin
    get :index
    assert_response :success
    assert_not_nil assigns(:video_clips)
  end

  def test_should_get_new
    login_as :quentin
    get :new
    assert_response :success
  end

  def test_should_create_video_clip
    login_as :kevin
    assert_difference(VideoClip,:count, 1) do
      post :create, :video_clip => {:title => "My First Tackle", :description => "my desc", :video_length => "0:0:25", :dockey => "abcdefghijklm", :video_asset_id => video_assets(:one).id, :user_id => users(:kevin).id  }
    end

    assert_redirected_to video_clip_path(assigns(:video_clip))
  end

  def test_should_show_video_clip
    login_as :quentin
    get :show, :id => video_clips(:one).id
    assert_response :success
  end

  def test_should_get_edit
    login_as :quentin
    get :edit, :id => video_clips(:one).id
    assert_response :success
  end

  def test_should_update_video_clip
    login_as :quentin
    put :update, :id => video_clips(:one).id, :video_clip => { }
    assert_redirected_to video_clip_path(assigns(:video_clip))
  end

  def test_should_destroy_video_clip
    login_as :quentin
    assert_difference(VideoClip, :count, -1) do
      delete :destroy, :id => video_clips(:one).id
    end

    assert_redirected_to video_clips_path
  end
  
  def test_update_tags
    login_as :admin
    tags = VideoClip.find(video_clips(:one).id).tags.collect(&:name)
    put :update, :id => video_clips(:one).id, :video_clip => {}, :tag_list => "newgoo bluegoo #{tags.join(' ')}"
    assert_redirected_to video_clip_path(assigns(:video_clip))
    assert_equal(tags.size+2, VideoClip.find(video_clips(:one).id).tags.size)
  end
end
