class BaseController < ApplicationController
  include Viewable

  before_filter :vidavee_login, :includes => [ :site_index ]

  # Turn off CE action caching, we are going to use Rails.cache
  def cache_action?
    false
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
      session[:vidavee] = @vidavee.username
      session[:vidavee_expires] = 5.minutes.from_now
    end
    @vidavee
  end
  
  def site_index

    # What does a logged in user see first?
    if(logged_in?)
      if (current_user.admin?)
        redirect_to(admin_dashboard_path) and return
      end
      redirect_to(dashboard_user_path(current_user)) and return
    end

    # Not logged in, show featured games and athletes
    @games_of_the_week = Rails.cache.fetch('games_of_the_week') { GameOfTheWeek.for_home_page || []}
    @athletes_of_the_week = AthleteOfTheWeek.for_home_page
    
    # Play the specified game
    if params[:id]
      @games_of_the_week.each do |video|
        if video.id.to_s == params[:id]
          @games_of_the_week.delete(video)
          @games_of_the_week.unshift(video)
          break
        end
      end
    end

    # First on the list if non specified or specified one not found
    @now_playing = @games_of_the_week.shift
    if @now_playing
      update_view_count(@now_playing)
    end
  end

end
