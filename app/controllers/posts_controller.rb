class PostsController < BaseController

  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :edit, :update, :create ])
  uses_tiny_mce(:options => AppConfig.simple_mce_options, :only => [:show])
  skip_before_filter :gs_login_required, :only => [:show_public]
  after_filter :cache_control, :only => [:update, :destroy, :create]

  # Allowed to show any of the featured athlete stories, but not just any story
  def show_public
#     @post = AthleteOfTheWeek.find(params[:id])
#     unless @post.category_id == AthleteOfTheWeek.my_category.id &&
#         (@post.user.league_staff? || @post.user.team_staff? || @post.user.admin?)
#       redirect_to :controller => 'base', :action => 'site_index' and return
#     end
#   rescue
#     redirect_to :controller => 'base', :action => 'site_index'
    @post = Post.find(params[:id])
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
  
  def index
    @user = User.find(params[:user_id])            
    @category = Category.find_by_name(params[:category_name]) if params[:category_name]
    cond = Caboose::EZ::Condition.new
    cond.user_id == @user.id
    if @category
      cond.append ['category_id = ?', @category.id]
    end
    @posts = Post.paginate(:all, :order => "published_at DESC", :conditions => cond.to_sql, :per_page => 20, :page => params[:page])
    # @pages, @posts = paginate :posts, :order => "published_at DESC", :conditions => cond.to_sql, :per_page => 20
    @is_current_user = @user.eql?(current_user)

    @popular_posts = @user.posts.find(:all, :limit => 10, :order => "view_count DESC")
    
    @rss_title = "#{AppConfig.community_name}: #{@user.login}'s posts"
    @rss_url = formatted_user_posts_path(@user,:rss)
        
    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render_rss_feed_for(@posts,
           { :feed => {:title => @rss_title, :link => url_for(:controller => 'posts', :action => 'index', :user_id => @user) },
             :item => {:title => :title,
                       :description => :post,
                       :link => :link_for_rss,
                       :pub_date => :published_at} })        
      }
    end
  end

  protected

  def cache_control
    if @post && @post.is_live? && @post.category.name == AthleteOfTheWeek.my_category.name
      Rails.cache.delete('athletes_of_the_week')
    end
  end
  
end
