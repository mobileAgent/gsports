class TopicsController < BaseController
  before_filter :login_required
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:show, :new])
end
