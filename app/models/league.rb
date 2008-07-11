class League < ActiveRecord::Base
  
  # Every league needs a name
  validates_presence_of :name
  
end
