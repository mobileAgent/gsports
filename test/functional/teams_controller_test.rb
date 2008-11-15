require 'test_helper'

class TeamsControllerTest < ActionController::TestCase

  fixtures :teams, :users, :roles, :leagues

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
    assert_difference(Team,:count,1) do
      post :create, :team => {:name => 'My Team', :nickname=> 'My Nick', :description => 'this is the description' , :league_name => leagues(:one).name }
    end

    assert_redirected_to teams_path
  end
  

end
