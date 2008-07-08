class UpdateVideoStatusProcessor < ApplicationProcessor

  subscribes_to :update_video_status

  def on_message(message)
    logger.debug "UpdateVideoStatusProcessor received: " + message

    # Get the asset from our db
    video_asset = VideoAsset.find(message)
    if !video_asset
      logger.debug "Invalid video_asset #{message} requested"
      return
    end

    # Log into the vidavee backend
    vidavee = Vidavee.find(:first)
    session_token = vidavee.login

    # Get their status
    new_status = video_asset.video_status
    while (new_status != 'ready' && new_status != 'blocked')
      new_status = vidavee.asset_status(session_token,video_asset.dockey)
      logger.debug "Trying to update status for #{message}, vidavee says '#{new_status}'"
      if new_status && new_status != video_asset.video_status
        video_asset.video_status = new_status
        video_asset.save!
        logger.debug "Updated video status for #{message} to #{new_status}"
        return
      end
      sleep 15
    end
  end
end
