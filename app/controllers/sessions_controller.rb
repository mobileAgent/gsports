class SessionsController < BaseController
  skip_before_filter :verify_authenticity_token, :only => [:new, :create]
  def index
    redirect_to :action => "new"
  end  
  
  # render new.rhtml
  def new
    redirect_to user_path(current_user.id) if current_user
    render :layout => 'beta' if AppConfig.closed_beta_mode
  end

  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in? && current_user.enabled?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end

      redirect_back_or_default(dashboard_user_path(current_user.id))
      flash[:notice] = "Thanks! You're now logged in."
      current_user.track_activity(:logged_in)
    else
      if !current_user.nil? && !current_user.enabled?
        flash[:notice] = "Your account is not enabled.  Please contact the gsports administrator."
      else
        flash[:notice] = "Uh oh. We couldn't log you in with the username and password you entered. Try again?"      
      end
        redirect_to teaser_path and return if AppConfig.closed_beta_mode        
        render :action => 'new'
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You've been logged out. Hope you come back soon!"
    redirect_to :controller => 'base', :action => 'site_index'
  end
end
