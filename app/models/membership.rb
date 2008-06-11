class Membership < ActiveRecord::Base
   has_many :addresses, :as => :addressable
   has_many :subscriptions
   has_many :users, :through => :subscriptions
   has_many :membership_billing_histories
end
