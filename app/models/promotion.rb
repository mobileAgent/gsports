class Promotion < ActiveRecord::Base
   validates_presence_of :promo_code
   validates_uniqueness_of :promo_code
   belongs_to :subscription_plan
   
end
