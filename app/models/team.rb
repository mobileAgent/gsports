class Team < ActiveRecord::Base

  # Every team needs a name
  validates_presence_of :name
  
end
