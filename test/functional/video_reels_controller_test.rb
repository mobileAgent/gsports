require 'test_helper'

class VideoReelsControllerTest < ActionController::TestCase

  fixtures :users, :roles, :video_reels

  def setup
    @controller = VideoReelsController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_sample_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert_not_nil assigns(:video_reels)
  end

  def test_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end

  def test_should_create_video_reel
    login_as :admin
    assert_difference(VideoReel, :count,1) do
      post :create, :video_reel => { :title => "This is a test reel", :dockey => "ABDCEF12345" }
    end

    assert_redirected_to video_reel_path(assigns(:video_reel))
  end

  def test_should_show_video_reel
    login_as :admin
    get :show, :id => video_reels(:one).id
    assert_response :success
  end

  def test_should_get_edit
    login_as :admin
    get :edit, :id => video_reels(:one).id
    assert_response :success
  end

  def test_should_update_video_reel
    login_as :admin
    put :update, :id => video_reels(:one).id, :video_reel => { }
    assert_redirected_to video_reel_path(assigns(:video_reel))
  end

  def test_should_destroy_video_reel
    login_as :admin
    assert_difference(VideoReel,:count, -1) do
      delete :destroy, :id => video_reels(:one).id
    end

    assert_redirected_to video_reels_path
  end
  
  def test_update_tags
    login_as :admin
    tags = VideoReel.find(video_reels(:one).id).tags.collect(&:name)
    put :update, :id => video_reels(:one).id, :video_reel => {}, :tag_list => "newcat bluecat #{tags.join(' ')}"
    assert_redirected_to video_reel_path(assigns(:video_reel))
    assert_equal(tags.size+2, VideoReel.find(video_reels(:one).id).tags.size)
  end
end
