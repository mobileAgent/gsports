class PostsController < BaseController

  before_filter :login_required, :only => [:new, :edit, :update, :destroy, :create, :manage, :show, :popular]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :edit, :update, :create ])
  uses_tiny_mce(:options => AppConfig.simple_mce_options, :only => [:show])
  
end
