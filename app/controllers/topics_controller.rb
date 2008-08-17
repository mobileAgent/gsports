class TopicsController < BaseController
  before_filter :login_required, :only => [:index, :show]
  before_filter :admin_required, :only => [:create, :new, :update, :destroy]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:show, :new])
end
