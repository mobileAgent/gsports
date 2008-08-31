class CommentsController < BaseController
  
  def show
    @comment = Comment.find(params[:id])
    @user = @comment.user
    respond_to do |format|        
      format.html
      format.js {render :text => @comment.inspect}
    end
  end
  
end  
