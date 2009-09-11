class GamexUser < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :league
  belongs_to :access_group
  
  
  named_scope :for_user,
    lambda { |user| { :conditions => { :user_id => user.id } } }

  named_scope :for_user_and_league,
    lambda { |user,league| { :conditions => { :user_id => user.id, :league_id => league.id } } }

  
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