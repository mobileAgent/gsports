class PostsController < BaseController

  before_filter :login_required, :only => [:new, :edit, :update, :destroy, :create, :manage, :show, :popular]
  
end
