class BillingController < BaseController
  
  before_filter :admin_required

  def index
    @memberships = Membership.find :all
    @users = User.find :all
  end

  def member_billing_history
    @member_name = Membership.find (params[:id]).name
    @billings = MembershipBillingHistory.find_all_by_membership_id(params[:id]) 
  end
end
