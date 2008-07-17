class PushVideoFilesProcessor < ApplicationProcessor
  include ActiveMessaging::MessageSender
  publishes_to :update_video_status

  subscribes_to :push_video_files

  def on_message(message)
    video_asset = VideoAsset.find(message)
    logger.debug "Push received: #{message} with path #{video_asset.uploaded_file_path}"
    vidavee = Vidavee.find(:first)
    session_token = vidavee.login
    dockey = vidavee.push_video session_token,video_asset,video_asset.uploaded_file_path
    if dockey
      logger.debug "Video push #{video_asset.uploaded_file_path} => #{dockey}"
      if (video_asset.video_status == 'queued')
        publish(:update_video_status,"#{video_asset.id}")
      end
    else
      logger.debug "Video push failed for #{video_asset.uploaded_file_path}"
    end
  end
end
