class AppliedMoniker < ActiveRecord::Base
  acts_as_taggable

  belongs_to :user
  belongs_to :moniker

  named_scope :for_user,
    lambda { |user| {:conditions => ["user_id = ?",user.id], :include => [:moniker, :tags] } }

  delegate :name, :to => :moniker
  
end
