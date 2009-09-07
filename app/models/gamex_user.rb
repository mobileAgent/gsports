class GamexUser < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :league
  
  def league_name
    league.name
  end
  
  def teams
  	GamexUser.find(:all, :conditions=>{ :league_id=>league_id }).collect() { |g| g.user.team }
  end
  
end