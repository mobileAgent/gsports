class GamexLeague < ActiveRecord::Base

  belongs_to :league
  #belongs_to :access_group

  
  def league_name= name
    league = League.find(:first, :conditions=>{ :name=>name })
    league_id = league.id if league
  end

  def league_name
    if league_id
      league = League.find(league_id)
      league ? league.name : '' rescue '!'
    end
  end


  def teams
    have_teams = {}
    team_list = []
      # , :include=>'team', :order=>'teams.name ASC'
      GamexUser.find(:all, :conditions=>{ :league_id=>league_id }).collect() { |g|
      team = g.user.team
      if have_teams[team.id]
        #drop, no fuss
      else
        team_list << team
        have_teams[team.id] = true
      end
    }
    team_list.sort_by { |team| team.name }
  end



  def release?(video_asset)
    return true if release_time.nil? or video_asset.gamex_release_override

    disperse_release_time()

    shift = 0

    vd = video_asset.ready_at

    return true if vd.nil?
    
    if vd.wday > release_day
      shift= (6-vd.wday+1) + release_day
    elsif vd.wday < release_day
      shift= vd.wday - release_day
    end

    logger.info("MEOW vd.wday #{vd.wday}, release_day #{release_day}")
    logger.info("MEOW shifting #{shift}")

    if shift > 0
      vd += shift * 60 * 60 * 24
    end

    hour = hour12to24(release_hour, release_apm)

    vd = vd.change(:hour => hour, :min => release_min)

    # is it in the future - fail
    return vd > ::DateTime.now()

  end







  attr :release_day, true
  attr :release_hour, true
  attr :release_min, true
  attr :release_apm, true

#  def release_day
#    @release_day
#  end
#
#  def release_day= d
#    @release_day= d
#  end
#
#  def release_hour
#    @release_hour
#  end
#
#  def release_hour= h
#    @release_hour = h
#  end
#
#  def release_min
#    @release_min
#  end
#
#  def release_min= m
#    @release_min = m
#  end
#
#  def release_apm
#    @release_apm
#  end
#
#  def release_apm= m
#    @release_apm= m
#  end





  before_save :collect_release_time
  #after_find :disperse_release_time


  def collect_release_time
#    logger.info("MEOW release_day #{release_day.inspect}")
#    logger.info("MEOW release_hour #{release_hour.inspect}")
#    logger.info("MEOW release_min #{release_min.inspect}")
#    logger.info("MEOW release_apm #{release_apm.inspect}")
    if release_day == 1
      self.release_time = nil
      return
    end

    hour = release_hour.to_i
    if release_apm.to_i == 1
      #pm
      hour += 12 if hour < 12 #12pm is just 12
    else
      hour = 0 if hour == 12 #12am is 0
    end

    time = release_day.to_i*24*60 + hour*60 + release_min.to_i
    self.release_time= (time > 0) ? time : nil
    #logger.info("MEOW #{a.inspect} > #{release_time}")
#    logger.info("MEOW release_time #{release_time.inspect}")
  end

  def hour12to24(h, apm)
    hour = h.to_i
    if apm.to_i == 1
      #pm
      hour += 12 if hour < 12 #12pm is just 12
    else
      hour = 0 if hour == 12 #12am is 0
    end
    hour
  end
    

  def disperse_release_time
    #TODO cache this


    if release_time.nil?
      self.release_day= -1
      return
    end

    m = release_time || 0

    #logger.info("ARF  #{m.inspect}")
    d = m / (24*60)
    m -= d * 24*60
    #logger.info("ARF  #{m.inspect}")
    h = m / 60
    m -= h *60
    #logger.info("ARF  #{m.inspect}")

    pm = 0

    case h
    when 0
      h= 12
    when 12
      pm =1
    when 13..23
      h-= 12
      pm =1
    end


    self.release_day= d
    self.release_hour= h
    self.release_min= m
    self.release_apm= pm
  end

  def release_time_str
    return '' if release_time.nil?

    disperse_release_time()

    "#{Days[release_day.to_i + 1][0]} #{release_hour}:#{("00"+release_min.to_s)[-2,2]}#{(release_apm.to_i == 1) ? 'pm' : 'am'}"
  end

#  def release_day
#    release_time ? release_time / (24*60) : 0
#  end
#
#  def release_day= d
#    edit_release_time{ |a| a[0] = d }
#  end
#
#  def release_hour
#    release_time_to_a[1]
#  end
#
#  def release_hour= h
#    edit_release_time{ |a| a[1] = h }
#  end
#
#  def release_min
#    release_time_to_a[2]
#  end
#
#  def release_min= m
#    edit_release_time{ |a| a[2] = m }
#  end
#
#
#  def edit_release_time(&block)
#    a = release_time_to_a
#    #logger.info("MEOW #{a.inspect}")
#    yield a
#    #logger.info("MEOW #{a.inspect}")
#    a_to_release_time(a)
#  end
#
#
#  def release_time_to_a
#    m = release_time || 0
#
#    #logger.info("ARF  #{m.inspect}")
#    d = m / (24*60)
#    m -= d * 24*60
#    #logger.info("ARF  #{m.inspect}")
#    h = m / 60
#    m -= h *60
#    #logger.info("ARF  #{m.inspect}")
#
#    [d,h,m]
#  end
#
#  def a_to_release_time(a)
#    #logger.info("MEOW #{a.inspect} > #{a[0]}*24*60 + #{a[1]}*60 + #{a[2]} > #{release_time}")
#    time = a[0].to_i*24*60 + a[1].to_i*60 + a[2].to_i
#    self.release_time= (time > 0) ? time : nil
#    #logger.info("MEOW #{a.inspect} > #{release_time}")
#  end

  Days = [
    ['None',-1],
    ['Sunday',0],
    ['Monday',1],
    ['Tuesday',2],
    ['Wednesday',3],
    ['Thursday',4],
    ['Friday',5],
    ['Saturday',6]
  ]

  #Hours = (0..23).collect(){ |h| if h < 12; ["#{h>0 ? h : 12}am", h]; else ["#{h==12 ? h : h-12}pm", h]; end }
  Hours = (1..12).collect(){ |h| [h, h] }

  Mins = [ ['00',0], ['15',15], ['30',30], ['45',45] ]

  APms = [ ['am', 0], ['pm',1] ]
  
end

