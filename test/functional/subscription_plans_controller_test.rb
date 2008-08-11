require 'test_helper'

class SubscriptionPlansControllerTest < ActionController::TestCase
  
  fixtures :subscription_plans, :users, :roles
  
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
    assert_not_nil assigns(:subscription_plans)
  end

  def test_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end

  def test_should_create_subscription_plan
    login_as :admin
    assert_difference(SubscriptionPlan,:count) do
      post :create, :subscription_plan => {:name=>'foo',:description=>'bar',:cost=>"15.95" }
    end

    assert_redirected_to subscription_plan_path(assigns(:subscription_plan))
  end

  def test_should_show_subscription_plan
    login_as :admin
    get :show, :id => subscription_plans(:basic).id
    assert_response :success
  end

  def test_should_get_edit
    login_as :admin
    get :edit, :id => subscription_plans(:basic).id
    assert_response :success
  end

  def test_should_update_subscription_plan
    login_as :admin
    put :update, :id => subscription_plans(:basic).id, :subscription_plan => {:cost => '10.95' }
    assert_redirected_to subscription_plan_path(assigns(:subscription_plan))
  end

  def test_should_destroy_subscription_plan
    login_as :admin
    assert_difference(SubscriptionPlan,:count, -1) do
      delete :destroy, :id => subscription_plans(:basic).id
    end

    assert_redirected_to subscription_plans_path
  end
end
