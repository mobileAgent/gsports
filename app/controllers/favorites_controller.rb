class FavoritesController < BaseController
  
  after_filter :expire_home_page, :only => [:create, :destroy, :remove]

  def remove
    @favorite = Favorite.user(current_user).item_type_id(params[:favoritable_type],params[:favoritable_id]).first
    @favorite.destroy if @favorite
    
    respond_to do |format|
      format.js { render :action => "destroy" }
    end    
  end

  protected

  def expire_home_page
    # Admins video favs change the home page
    if current_user.admin? && @favorite && !@favorite.new_record? &&
        @favorite.video_type?
      logger.debug "Clearing gotw cache due to admin favorite #{@favorite.id}"
      Rails.cache.delete('games_of_the_week')
    end
  end
  
end
