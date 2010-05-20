class SessionsController < BaseController
  skip_before_filter :verify_authenticity_token, :only => [:new, :create]
  skip_before_filter :gs_login_required, :only => [:new, :create, :destroy, :pop_login_box]
  skip_before_filter :billing_required, :only => [:new, :create, :destroy]
  
  def index
    redirect_to :action => "new"
  end  
  
  # render new.rhtml
  def new
    redirect_to dashboard_user_path(current_user.id) if current_user
    render :layout => 'beta' if AppConfig.closed_beta_mode
  end

  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if current_user.enabled?
        if params[:remember_me] == "1"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        end
        #session[:return_to] = params[:session_return_to]
        redirect_back_or_default(dashboard_user_path(current_user.id))
        flash[:notice] = "Thanks! You're now logged in."
        current_user.track_activity(:logged_in)
      else
        #ppv
        redirect_to :controller => 'users', :action => 'ppv'
        flash[:notice] = "Thanks! You're now logged in."
        current_user.track_activity(:logged_in)
      end
    else
      self.current_user = nil
      inactive_user = User.authenticate_inactive(params[:login],params[:password])
      if (inactive_user)
        if inactive_user.pending_purchase_order?
          flash[:error] = "Your payment has not been received or processed yet."
          redirect_to(url_for(:controller => 'base', :action => 'site_index')) and return false
        else
          flash[:error] = 'Your account is inactive. You must provide billing information'
          redirect_to :controller => 'users', :action => 'billing', :userid => inactive_user.id and return
        end
      else
        flash[:error] = "Uh oh. We couldn't log you in with the username and password you entered. Your username is your email address. Try again?"
      end
      redirect_to teaser_path and return if AppConfig.closed_beta_mode        
      redirect_to :controller => 'base', :action => 'site_index' and return
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You've been logged out. Hope you come back soon!"
    redirect_to :controller => 'base', :action => 'site_index'
  end
  
  def pop_login_box 
    #TODO, if they've already logged in, maybe by another window, let them pass
    
    
    
    
    render :update do |page|
      page.replace_html 'dialog', :partial => 'shared/register'
    end
    
  end
  
end



