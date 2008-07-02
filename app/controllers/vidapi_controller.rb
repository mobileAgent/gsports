class VidapiController < ApplicationController
  
  # GET /vidapi/login
  # log into the vidavee backend and get a session token
  def login
    @vidavee = Vidavee.find(:first)
    if (session[:vidavee].nil?)
      session[:vidavee] = @vidavee.login
    end
    @dockey = params[:dockey] || '018F8DACEFE48C219653F781EE72690F'
  end

  # GET /vidapi/logout
  # Cancel our token with the back end
  def logout
    if (session[:vidavee])
      @vidavee = Vidavee.find(:first)
      @vidavee.logout(session[:vidavee])
      cache.delete('vidavee')
      session[:vidavee] = nil
    end
  end
  
end
