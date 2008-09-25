class BillingController < BaseController
  
  before_filter :admin_required

  def index
    @memberships = Membership.find(:all, :include => 'user')
    # @users = User.find :all
  end

end
