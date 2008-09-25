class RatingsController < BaseController
  
  def rate
    item, rating = save_rating()
    render :text => "Rated #{rating.rateable_type}(#{rating.rateable_id}) with #{rating.rating}"
  end
  
  def update_rating
    item, rating = save_rating()
    target = "rate-#{rating.rateable_type}-#{rating.rateable_id}"

    render :update do |page|
      page.replace_html target, :partial => 'stars', :locals => { :item => item }
    end
  end
  
  private
  
  def save_rating
    type = params[:type].gsub(/[^a-zA-Z]/,'')
    id = params[:id].to_i
    item = eval "#{type}.find(#{id})"
    
    Rating.delete_all(["rateable_type = '#{item.class}' AND rateable_id = ? AND user_id = ?", item.id, current_user.id])
    
    rating = Rating.new
    rating.user_id = current_user.id
    rating.rating = params[:rating]
    
    item.add_rating rating
    
    [item, rating]
  end
  
  
end