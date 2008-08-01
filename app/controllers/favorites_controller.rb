class FavoritesController < BaseController
  
  def remove
    @favorite = Favorite.user(current_user).item_type_id(params[:favoritable_type],params[:favoritable_id]).first
    @favorite.destroy if @favorite
    
    respond_to do |format|
      format.js { render :action => "destroy" }
    end    
  end
end
