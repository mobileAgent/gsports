class MembershipCancellation < ActiveRecord::Base
  belongs_to :membership # fk: membership_id
end
