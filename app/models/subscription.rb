class Subscription < ActiveRecord::Base
   belongs_to :membership
   belongs_to :user
end
