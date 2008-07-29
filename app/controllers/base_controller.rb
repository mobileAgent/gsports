class BaseController < ApplicationController

  before_filter :vidavee_login, :includes => [ :site_index ]
  
  def test
    @test_str = :meow
  end

  # Everyone visiting the site needs a vidavee login, even
  # unauthenticate users, so that they can see videos with a
  # valid vidavee sessionid and dockey.
  def vidavee_login
    # @vidavee = Rails.cache.fetch('vidavee') { Vidavee.first }
    @vidavee = Vidavee.first
    if (session[:vidavee].nil? || 
        session[:vidavee_expires].nil? || session[:vidavee_expires] < Time.now)
      session[:vidavee] = @vidavee.login
      session[:vidavee_expires] = 5.minutes.from_now
    end
    @vidavee
  end
  
  def site_index
    redirect_to(dashboard_user_path(current_user)) if logged_in?
  end
  

end
