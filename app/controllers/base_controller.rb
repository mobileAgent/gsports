class BaseController < ApplicationController
  include Viewable

  before_filter :vidavee_login
  before_filter :gs_login_required, :except => [:site_index, :beta]
  before_filter :billing_required, :except => [:site_index, :beta]
  before_filter :quickfind_setup

  # Show the lockout page
  def beta
    render :layout => false
  end
  
  def site_index

    logger.debug "In site index action "

    # What does a logged in user see first?
    if(logged_in?)
      if (current_user.admin?)
        redirect_to(admin_dashboard_path) and return
      end
      redirect_to(dashboard_user_path(current_user)) and return
    end

    # Not logged in, show featured games and athletes
    @athletes_of_the_week =
      Rails.cache.fetch('athletes_of_the_week', :expires_in => 30.minutes) do
      AthleteOfTheWeek.for_home_page
    end
    @articles_of_the_week =
      Rails.cache.fetch('articles_of_the_week', :expires_in => 30.minutes) do
      Post.highlighted_articles(@athletes_of_the_week.collect(&:id)) 
    end
    @games_of_the_week =
      Rails.cache.fetch('games_of_the_week', :expires_in => 30.minutes) do
      GameOfTheWeek.for_home_page || []
    end
    @game_dockey_string = @games_of_the_week.collect(&:dockey).join(",")
  end

  # Turn off CE action caching, we are going to use Rails.cache
  def cache_action?
    false
  end
  
  protected

  # This is a wrapper around the CE base_controllers login_required
  # which is commonly used as a before_filter. Really it comes from
  # CE/lib/authenticated_system. But many of the CE controllers use
  # it like
  #   before_filter :login_required, :except => [:foo]
  # or 
  #   before_filter :login_required, :only => [:foo]
  # 
  # Results vary dramatically in trying to add additional methods
  # that CE felt did not need to be protected, but which we
  # do want to protect. There is no (not yet) :exclude or :include
  # method on before_filter so in some cases it is just ignored.
  # Our solution to this it to just add the required hook as another
  # name so that we can require it where we need it with a very
  # simple syntax. The call is fast, not reuiring a DB
  # lookup, so that should not present too much of a problem
  #
  # The system is totally authenticated now except for actions
  # which have skip_before_filter for this filter.
  # It is easy to audit that all controllers extend from this
  # one and that only those actions which explicity skip this filter
  # should be viewable to the public side.
  def gs_login_required
    login_required
  end

  # Ensure the status of the users billing
  def billing_required
    # Need to check that when they edit billing, we go ahead
    # and charge them at that time. Also the edit billng
    # form is lame needs to look more like the registration form
    #return true # Not ready to enable this yet 
    return true if current_user.nil?
   
    if current_user.billing_needed? || current_user.credit_card_expired?
      flash[:error] = "Your billing information must be updated!"
      redirect_to(url_for(:controller => 'users', :action => 'edit_billing')) and return false
    end
    
    membership_required
  end

  # Ensure the status of the users membership, accounts for promotional period expirations
  def membership_required
    return true if current_user.nil?

    membership = current_user.membership;
    return true if membership.nil?

    if membership.expired?
      flash[:error] = "Your membership has expired. Please renew your account."
      redirect_to(url_for(:controller => 'users', :action => 'account_expired')) and return false
    end
    return true
  end


  # Everyone visiting the site needs a vidavee login, even
  # unauthenticate users, so that they can see videos with a
  # valid vidavee sessionid and dockey.
  def vidavee_login

    begin
      @vidavee = Rails.cache.fetch('vidavee') { Vidavee.first }
    rescue
      logger.debug "Vidavee in cache is bad, replacing"
      Rails.cache.delete('vidavee')
      @vidavee = Rails.cache.fetch('vidavee') { Vidavee.first }
    end
    
    if (session[:vidavee].nil? || 
        session[:vidavee_expires].nil? || session[:vidavee_expires] < Time.now)
      logger.debug "Logging into vidavee again"
      session[:vidavee] = @vidavee.login()
      session[:vidavee_expires] = 5.minutes.from_now
    end
    @vidavee
  end

  # Set up information we need to drive the quickfind dropdowns
  # mostly memcached when running with memcached turned on
  def quickfind_setup
    @quickfind_seasons = Rails.cache.fetch('quickfind_seasons') { VideoAsset.seasons }
    @quickfind_schools = Rails.cache.fetch('quickfind_schools') { Team.having_videos.find(:all, :order => "name ASC") }
    @quickfind_states = Rails.cache.fetch('quickfind_states') { Team.states }
    @quickfind_counties = Rails.cache.fetch('quickfind_counties') { Team.counties }
    @quickfind_sports = Rails.cache.fetch('quickfind_sports') { VideoAsset.sports }
    @quickfind_cities = Rails.cache.fetch('quickfind_cities') { Team.cities }
  end

end
