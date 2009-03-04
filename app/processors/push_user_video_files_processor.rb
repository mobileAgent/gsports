class PushUserVideoFilesProcessor < ApplicationProcessor
  include ActiveMessaging::MessageSender
  publishes_to :update_video_status

  subscribes_to :push_user_video_files

  def on_message(message)
    logger.debug "!!! PushUserVideoFilesProcessor: #{message}"
    video_user = VideoUser.find(message)
    logger.debug "Push received: #{message} with path #{video_user.uploaded_file_path}"
    vidavee = Vidavee.find(:first)
    session_token = vidavee.login
    dockey = vidavee.push_video session_token,video_user,video_user.uploaded_file_path
    if dockey
      logger.info "Video push #{video_user.uploaded_file_path} => #{dockey}"
    else
      fullpath = video_user.uploaded_file_path
      fn = fullpath[File.dirname(fullpath).length+1..-1]
      logger.info "Video push failed for #{fullpath}"
      [User.find_by_email(ADMIN_EMAIL),video_user.user_id].uniq.each do |u|
        m = Message.create(:title => "Video upload failed for #{fn}",
                           :body => "Video file #{fn} could not be pushed to the backend video engine. /video_users/#{video_user.id}",
                           :from_id => User.find_by_email(ADMIN_EMAIL).id,
                           :to_id => u )
      end
    end
  end
  
end
