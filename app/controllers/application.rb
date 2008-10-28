# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  
  helper :all # include all helpers, all the time
  before_filter :preload_models
  before_filter :beta_mode

  # Let exception notifier work on all controllers
  include ExceptionNotifiable
  
  # Help with ssl switching
  include SslRequirement
  
  # The Community Engine overridden layout needs this
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '1445b9bcd1509d30d78d2652022f83b8'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password, :password_confirm, :verification_value, :cardnumber, :verificationnumber, :credit_card

  protected

  def beta_mode
    if (CLOSED_BETA_MODE)
      unless ALLOWED_IP_ADDRS.member?(request.remote_ip)
        render :template => 'base/beta', :layout => false and return
      end
    end
    return true
  end

  def admin_for_league_or_team
    (current_user.admin? || current_user.league_admin? || current_user.team_admin?) ? true : access_denied
  end
  
  # Allow these models to be memcached
  def preload_models
    Role
    Tag
    State
    Team
    League
    Moniker
    User
    Favorite
    SharedItem
    SharedAccess
    VideoAsset
    VideoClip
    VideoReel
    GameOfTheWeek
    AthleteOfTheWeek
    Vidavee
    Post
    Message
    Staff
  end

  def expire_games_of_the_week
    if (current_user.admin?)
      logger.debug "Clearing gotw cache due to admin video action"
      Rails.cache.delete('games_of_the_week')
    end
  end
  
end
