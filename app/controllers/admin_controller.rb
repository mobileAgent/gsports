class AdminController < BaseController

  before_filter :admin_required
  
  def dashboard
  end

end
