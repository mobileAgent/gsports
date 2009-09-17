class GamexUser < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :league
  belongs_to :access_group
  
  
  named_scope :for_user,
    lambda { |user| { :conditions => { :user_id => user.id } } }

  named_scope :for_user_and_league,
    lambda { |user_id,league_id|
    
      
      { :conditions => { :user_id => user_id, :league_id => league_id } }

    }

  
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
  
  
  
  
end
