class VidapiController < BaseController
  
  before_filter :vidavee_login, :except => :logout
  
  # GET /vidapi/logout
  # Cancel our token with the back end
  def logout
    if (session[:vidavee])
      @vidavee = Vidavee.find(:first)
      @vidavee.logout(session[:vidavee])
      session[:vidavee] = nil
      session[:vidavee_expires] = Time.now
    end
  end
  
end
