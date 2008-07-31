class FavoritesController < BaseController
  
  def remove
    puts "In remove"
    @favorite = Favorite.user(current_user).item_type_id(params[:favoritable_type],params[:favoritable_id]).first
    puts "Found #{@favorite} in remove"
    @favorite.destroy
    puts "Did the destroy in remove"
    
    respond_to do |format|
      format.js { render :action => "destroy" }
    end    
  end
end
