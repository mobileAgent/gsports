class SbPostsController < BaseController
  before_filter :find_forum, :only => [:create, :index]
  before_filter :require_topic, :only => [:create]

  def destroy
    @post.destroy
    flash[:notice] = "Post: '#{CGI::escapeHTML @post.topic.title}' was deleted."
    # check for posts_count == 1 because its cached and counting the currently deleted post
    @post.topic.destroy and redirect_to forum_path(params[:forum_id]) if @post.topic.sb_posts_count == 1
    respond_to do |format|
      format.html do
        redirect_to forum_topic_path(:forum_id => params[:forum_id], :id => params[:topic_id], :page => params[:page]) unless performed?
      end
      format.xml { head 200 }
    end
  end  
    	
  protected
    #overide for community_engine SbPostsController
    def authorized?
    	current_user.admin? || @post.editable_by?(current_user) 
    end
	
	#overide for community_engine SbPostsController
	# html action is forced to .rhtml in default method
	def render_posts_or_xml(template_name = action_name)
	  respond_to do |format|
		format.html { render :action => template_name }
		format.rss  { render :action => "#{template_name}.rxml", :layout => false }
		format.xml  { render :xml => @posts.to_xml }
	  end
	end
	
	def find_forum
	  if params[:forum_id] != nil
		  @forum = Forum.find params[:forum_id]
	  end
	end		
	
	def require_topic
	  @topic = Topic.find_by_id_and_forum_id(params[:topic_id],@forum, :include => :forum)
		if @topic == nil
	    flash[:notice] = 'This topic is invalid'
		redirect_to(forum_path(@forum))
		end
	end	
end
