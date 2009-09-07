class GamexUser < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :league
  
  
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
  	GamexUser.find(:all, :conditions=>{ :league_id=>league_id }).collect() { |g| g.user.team }
  end
  
end