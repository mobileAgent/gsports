require 'test_helper'

class LeaguesControllerTest < ActionController::TestCase

  fixtures :users, :roles, :leagues, :states

  def setup
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @request.session[:vidavee] = 'vidavee_login_token'
    @request.session[:vidavee_expires] = 5.minutes.from_now
  end
  
  def test_index
    login_as :admin
    get :index
    assert_response :success
  end

  def test_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end
  
  def test_should_create
    login_as :admin
    assert_difference(League,:count,1) do
      post :create, :league => {:name => 'My New League', :description => 'this is the description', :city => 'Carlsbad', :state_id => states(:michigan).id, :zip => '98765' }
    end
    
    assert_redirected_to leagues_path
  end
  

end
