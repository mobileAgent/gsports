class SearchController < BaseController
  skip_before_filter :verify_authenticity_token, :only => [ :quickfind ]
  
  def quickfind
    cond = Caboose::EZ::Condition.new
    cond.append ['state_id = ?', params[:state]]
    cond.append ['county_name = ?', params[:county_name]]
    cond.append ['league_id = ?', params[:league]]
    cond.append ['sport = ?', params[:sport]]
    @pages, @video_assets = paginate :video_assets, :conditions => cond.to_sql, :order => 'created_at DESC', :include => :tags
  end

  def search
  end

end
