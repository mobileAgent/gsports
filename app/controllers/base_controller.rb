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

    # Not logged in, show the games of the week
    @games_of_the_week = GameOfTheWeek.find || []
    logger.debug "The specified param is #{params[:id]} choices are #{@games_of_the_week.collect(&:id).join(',')}"
    # Play the specified game
    if params[:id]
      @games_of_the_week.each do |video|
        if video.id.to_s == params[:id]
          logger.debug "Got a hit at #{params[:id]}"
          @games_of_the_week.delete(video)
          @games_of_the_week.unshift(video)
          break
        else
          logger.debug "Miss for param #{params[:id]} video id #{video.id}"
        end
      end
    end

    # First on the list if non specified or specified one not found
    logger.debug "Revised list is #{@games_of_the_week.collect(&:id).join(',')}"
    @now_playing = @games_of_the_week.shift
    logger.debug "The now_playing id is #{@now_playing.id}"
    
  end

end
