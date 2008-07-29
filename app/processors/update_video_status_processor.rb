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
    attempt=0
    while (new_status != 'ready' && new_status != 'blocked')
      new_status = vidavee.asset_status(session_token,video_asset.dockey)
      logger.debug "Trying to update status for #{message}, vidavee says '#{new_status}'"
      if new_status && new_status != video_asset.video_status
        logger.debug "Updated video status for #{message} to #{new_status}"
        if (new_status == 'ready')
          vidavee.update_asset_record(session_token,video_asset)
          video_asset.save!
          if video_asset.uploaded_file_path
            File.rm_f video_asset.uploaded_file_path
          end
        else
          video_asset.video_status = new_status
          video_asset.save!
          # Send someone a message about the failure, we still have the file
          # so we could re-upload for them or let someone decide what to do
          fullpath = video_asset.uploaded_file_path
          fn = fullpath[File.dirname(fullpath).length+1..-1]
          [User.find_by_email(ADMIN_EMAIL),video_asset.user_id].uniq.each do |u|
            m = Message.create(:title => "Video transcoding failed for #{fn}",
                               :body => "Video file #{fn} could not be transcoded by the backend video engine. We still have the file in #{fullpath}, so a retry can be attempted. The last status for this video was '#{new_status}' and the backend dockey value is '#{video_asset.dockey}'",
                               :from_id => User.find_by_email(ADMIN_EMAIL).id,
                               :to_id => u )
          end
        end
        return
      end
      attempt += 1
      if (attempt > 50)
        logger.error "Video asset #{video_asset.id} is stuck in state #{new_status} after maximum tries"
        return
      end
      sleep (2*attempt)
    end
  end
end
