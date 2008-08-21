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
  
  
  # POST /posts
  # POST /posts.xml
  def create    
    @user = User.find(params[:user_id])
    @post = Post.new(params[:post])
    @post.user = @user
    @post.team = @user.team if @user.team_staff?
    @post.league = @user.league if @user.league_staff?
    
    respond_to do |format|
      if @post.save
        @post.create_poll(params[:poll], params[:choices]) if params[:poll]
        
        @post.tag_with(params[:tag_list] || '') 
        flash[:notice] = @post.category ? "Your '#{Inflector.singularize(@post.category.name)}' post was successfully created." : "Your post was successfully created."
        format.html { 
          if @post.is_live?
            redirect_to @post.category ? category_path(@post.category) : user_post_path(@user, @post) 
          else
            redirect_to manage_user_posts_path(@user)
          end
        }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  
end
