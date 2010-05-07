class SharedAccessController < BaseController
  skip_before_filter :gs_login_required, :only => [:show]
  skip_before_filter :billing_required, :only => [:show]
 
  def show
    @shared_access= SharedAccess.find_by_key(params[:key])
    @shared_item= @shared_access.item

    # do not redirect if we are embedding the video
    unless params[:embed]
      if current_user
        case @shared_access.item_type
        when SharedAccess::TYPE_CLIP
          redirect_to user_video_clip_path(@shared_item.user_id, @shared_access.item_id)
        when SharedAccess::TYPE_REEL
          redirect_to user_video_reel_path(@shared_item.user_id, @shared_access.item_id)
        when SharedAccess::TYPE_VIDEO
          redirect_to user_video_asset_path(@shared_item.user_id, @shared_access.item_id)
        when SharedAccess::TYPE_USERVIDEO
          redirect_to user_video_user_path(@shared_item.user_id, @shared_access.item_id)
        end
      end

      # set up the athletes of the week, etc.
      prepare_site_index_content
    end
    
    if @shared_access.video?
      if @game_dockey_string
        @game_dockey_string = @shared_item.dockey + "," + @game_dockey_string
      else
        @game_dockey_string = @shared_item.dockey
      end
    end


  rescue Exception => e
    logger.error "#{e.message}"
    flash[:notice] = 'That item could not be found.'
    redirect_to url_for({ :controller => "base", :action => "site_index" })
  end
end
