require 'test_helper'

class GamexUsersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:gamex_users)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_gamex_user
    assert_difference('GamexUser.count') do
      post :create, :gamex_user => { }
    end

    assert_redirected_to gamex_user_path(assigns(:gamex_user))
  end

  def test_should_show_gamex_user
    get :show, :id => gamex_users(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => gamex_users(:one).id
    assert_response :success
  end

  def test_should_update_gamex_user
    put :update, :id => gamex_users(:one).id, :gamex_user => { }
    assert_redirected_to gamex_user_path(assigns(:gamex_user))
  end

  def test_should_destroy_gamex_user
    assert_difference('GamexUser.count', -1) do
      delete :destroy, :id => gamex_users(:one).id
    end

    assert_redirected_to gamex_users_path
  end
end
