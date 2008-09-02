class ForumsController < BaseController

  before_filter :admin_required , :only => [:create, :update, :destroy]
  uses_tiny_mce :options => AppConfig.gsdefault_mce_options

  protected

  def authorized?
    current_user
  end
end
