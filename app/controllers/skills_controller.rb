class SkillsController < BaseController
  before_filter :login_required, :only => [:new, :create, :edit, :update, :destroy, :index]
end
