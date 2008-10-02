class PurchaseOrder < ActiveRecord::Base
  
  belongs_to :user
  has_one :membership
  
  validates_presence_of :rep_name
  validates_presence_of :po_number
  validates_presence_of :user_id
  
  def gs_po_number
    "#{user_id}-#{created_at.to_i}"
  end
  
  def org
    if user.team_staff?
      user.team 
    else #if user.league_staff?
      user.league
    end
  end
  
  def description
    if user.team_staff?
      "Monthly Member Firm Subscription"
    else #if user.league_staff?
      "Monthly Sponsor Organization Subscription"
    end
  end
  
  def item_number
    user.role_id
  end
  
  def date
    created_at.strftime '%d-%m-%Y'
  end
  
  def accepted?
    accepted
  end
  
  def accepted_by_user
    accepted_by ? User.find(accepted_by) : nil
  end
  
end
