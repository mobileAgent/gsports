class CategoriesController < BaseController

  before_filter :login_required, :except => [:rss]

  def forums
    @categories = Category.find(:all)
  end     

  # GET /categories/1
  # GET /categories/1.xml
  def show
    @category = Category.find(params[:id])
    @sidebar_right = true
    
    cond = Caboose::EZ::Condition.new
    cond.category_id  == @category.id
    cond.append 'published_at IS NOT NULL'
    order = (params[:popular] ? "view_count #{params[:popular]}": "published_at DESC")
    @posts = Post.paginate(:all, :order => order, :conditions => cond.to_sql, :include => :tags, :page => params[:page])
    # @pages, @posts = paginate :posts, :order => order, :conditions => cond.to_sql, :include => :tags
    
    @popular_posts = @category.posts.find(:all, :limit => 10, :order => "view_count DESC")
    @popular_polls = Poll.find_popular_in_category(@category)

    @rss_title = "#{AppConfig.community_name}: #{@category.name} posts"
    @rss_url = formatted_category_path(@category, :rss)

    @active_users = User.find(:all,
      :include => :posts,
      :limit => 5,
      :conditions => ["posts.category_id = ? AND posts.published_at > ?", @category.id, 14.days.ago],
      :order => "users.view_count DESC"
      )
    
    respond_to do |format|
      format.html # show.rhtml
      format.rss {
        render_rss_feed_for(@posts, {:feed => {:title => "#{AppConfig.community_name}: #{@category.name} posts", :link => category_url(@category)},
          :item => {:title => :title, :link => :link_for_rss, :description => :post, :pub_date => :published_at} })        
      }
    end
  end 

end
