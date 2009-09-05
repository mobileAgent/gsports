class GamexUser < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :league
  
  def league_name
    league.name
  end
  
end