class MembershipController < BaseController

  before_filter :require_current_user, :only => [:member_billing_method_info, :member_billing_history ]
  
  before_filter :admin_required, :only => [:index ]
  
  
  
  sortable_attributes :id, :name, :billing_method, :cost, :created_at, :updated_at, :promotion_id, :user_id, :status, :expiration_date, 'promotions.promo_code'


  def index
    user_id = params[:user_id]
    if user_id
      @user = User.find(user_id)
      cond = ['user_id = ?', @user]
    else
      cond = {}
    end
    @memberships = Membership.paginate :all, :conditions => cond, :order=>sort_order, :include => [ :promotion ], :page => params[:page]
  end
  
  
  def member_billing_method_info
    @member = Membership.find params[:id]
  end

  def member_billing_history
    @member = Membership.find params[:id]
    @billings = MembershipBillingHistory.find_all_by_membership_id(params[:id])
  end
  
  
end
