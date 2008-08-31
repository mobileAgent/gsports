class BaseController < ApplicationController
  include Viewable

  before_filter :vidavee_login
  before_filter :gs_login_required, :except => [:site_index, :beta]

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
    @games_of_the_week = Rails.cache.fetch('games_of_the_week') { GameOfTheWeek.for_home_page || []}
    @game_dockey_string = @games_of_the_week.collect(&:dockey).join(",")
    @athletes_of_the_week = AthleteOfTheWeek.for_home_page
    @articles_of_the_week = Post.highlighted_articles(@athletes_of_the_week.collect(&:id))

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
    return login_required
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

end
