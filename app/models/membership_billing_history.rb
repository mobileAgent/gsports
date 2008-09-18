class MembershipBillingHistory < ActiveRecord::Base
   belongs_to :membership # fk: membership_id
   belongs_to :credit_card # fk: credit_card_id
end
