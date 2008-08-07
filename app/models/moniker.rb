class Moniker < ActiveRecord::Base

  has_many :users, :through => :applied_monikers

  named_scope :system, :conditions => ["user_generated = false"]
  named_scope :user, :conditions => ["user_generated = true"]
  
end
