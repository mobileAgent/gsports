class SubscriptionPlan < ActiveRecord::Base
   validates_presence_of :name, :cost
   has_one :role
end
