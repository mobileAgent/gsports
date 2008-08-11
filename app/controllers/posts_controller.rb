class PostsController < BaseController

  before_filter :login_required, :only => [:new, :edit, :update, :destroy, :create, :manage, :show, :popular]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :edit, :update, :create ])
  uses_tiny_mce(:options => AppConfig.simple_mce_options, :only => [:show])

  # Allowed to show any of the featured athlete stories, but not just any story
  def show_public
    @post = AthleteOfTheWeek.find(params[:id])
    unless @post.category_id == AthleteOfTheWeek.my_category.id &&
        (@post.user.league_staff? || @post.user.team_staff? || @post.user.admin?)
      redirect_to :controller => 'base', :action => 'site_index' and return
    end
  rescue
    redirect_to :controller => 'base', :action => 'site_index'
  end
  
end
