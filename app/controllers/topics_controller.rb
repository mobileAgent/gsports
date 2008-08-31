class TopicsController < BaseController
  
  before_filter :admin_required, :only => [:destroy]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:show, :new])

  protected
  
    def authorized?
      current_user
    end
end
