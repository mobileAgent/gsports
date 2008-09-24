class RatingsController < BaseController
  
  
  def rate
    
    type = params[:type].gsub(/[^a-zA-Z]/,'')
    id = params[:id].to_i
    item = eval "#{type}.find(#{id})"
    
    Rating.delete_all(["rateable_type = '#{item.class}' AND rateable_id = ? AND user_id = ?", item.id, current_user.id])
    
    rating = Rating.new
    rating.user_id = current_user.id
    rating.rating = params[:rating]
    
    item.add_rating rating
    
    target = "rate-#{type}-#{id}"
    
    render :update do |page|
      page.replace_html target, :partial => 'stars', :locals => { :item => item }
    end
  end
  
  
end