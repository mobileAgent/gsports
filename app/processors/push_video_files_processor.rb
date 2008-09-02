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
      logger.info "Video push #{video_asset.uploaded_file_path} => #{dockey}"
      #if (video_asset.video_status == 'queued')
      #  publish(:update_video_status,"#{video_asset.id}")
      #end
    else
      fullpath = video_asset.uploaded_file_path
      fn = fullpath[File.dirname(fullpath).length+1..-1]
      logger.info "Video push failed for #{fullpath}"
      [User.find_by_email(ADMIN_EMAIL),video_asset.user_id].uniq.each do |u|
        m = Message.create(:title => "Video upload failed for #{fn}",
                           :body => "Video file #{fn} could not be pushed to the backend video engine.",
                           :from_id => User.find_by_email(ADMIN_EMAIL).id,
                           :to_id => u )
      end
    end
  end
  
end
