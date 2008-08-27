class MembershipController < BaseController

  before_filter :login_required
  before_filter :require_current_user

  def member_billing_method_info
    @member = Membership.find params[:id]
  end

  def member_billing_history
    @member_name = Membership.find (params[:id]).name
    @billings = MembershipBillingHistory.find_all_by_membership_id(params[:id])
  end
end
