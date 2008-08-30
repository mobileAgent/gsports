class AdminController < BaseController

  before_filter :admin_required
  
  def dashboard
    logger.debug "In admin dashboard action"
  end

end
