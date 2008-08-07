require 'test_helper'

class MonikersControllerTest < ActionController::TestCase
  
  fixtures :monikers, :users, :roles
  
  def setup
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert_not_nil assigns(:monikers)
  end

  def test_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end

  def test_should_create_moniker
    login_as :admin
    assert_difference(Moniker,:count,1) do
      post :create, :moniker => {:name => "cars" }
    end

    assert_redirected_to moniker_path(assigns(:moniker))
  end

  def test_should_show_moniker
    login_as :admin
    get :show, :id => monikers(:one).id
    assert_response :success
  end

  def test_should_get_edit
    login_as :admin
    get :edit, :id => monikers(:one).id
    assert_response :success
  end

  def test_should_update_moniker
    login_as :admin
    put :update, :id => monikers(:one).id, :moniker => { }
    assert_redirected_to moniker_path(assigns(:moniker))
  end

  def test_should_destroy_moniker
    login_as :admin
    assert_difference(Moniker,:count, -1) do
      delete :destroy, :id => monikers(:one).id
    end

    assert_redirected_to monikers_path
  end
end
