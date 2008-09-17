require 'test_helper'

class PromotionsControllerTest < ActionController::TestCase
  
  fixtures :promotions, :subscription_plans
  
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
    assert_not_nil assigns(:promotions)
  end

  def test_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end

  def test_should_create_promotion        
    login_as :admin
    assert_difference(Promotion, :count) do
      post :create, :promotion => {:promo_code => 'foo', :name => 'bar', :cost => 0.00 }
    end

    assert_redirected_to promotion_path(assigns(:promotion))
  end

  def test_should_show_promotion
    login_as :admin
    get :show, :id => promotions(:free_promo).id
    assert_response :success
  end

  def test_should_get_edit
    login_as :admin
    get :edit, :id => promotions(:free_promo).id
    assert_response :success
  end

  def test_should_update_promotion
    login_as :admin
    put :update, :id => promotions(:free_promo).id, :promotion => { :cost => 1.00 }
    assert_redirected_to promotion_path(assigns(:promotion))
  end

  def test_should_destroy_promotion
    login_as :admin
    assert_difference(Promotion, :count, -1) do
      delete :destroy, :id => promotions(:free_promo).id
    end

    assert_redirected_to promotions_path
  end
end
