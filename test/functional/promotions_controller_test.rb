require 'test_helper'

class PromotionsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:promotions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_promotion
    assert_difference('Promotion.count') do
      post :create, :promotion => { }
    end

    assert_redirected_to promotion_path(assigns(:promotion))
  end

  def test_should_show_promotion
    get :show, :id => promotions(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => promotions(:one).id
    assert_response :success
  end

  def test_should_update_promotion
    put :update, :id => promotions(:one).id, :promotion => { }
    assert_redirected_to promotion_path(assigns(:promotion))
  end

  def test_should_destroy_promotion
    assert_difference('Promotion.count', -1) do
      delete :destroy, :id => promotions(:one).id
    end

    assert_redirected_to promotions_path
  end
end
