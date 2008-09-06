require 'vendor/plugins/community_engine/app/models/comment'

class Comment < ActiveRecord::Base

  def commentable_name
    type = Inflector.underscore(self.commentable_type)
    case type
      when 'user'
        commentable.full_name
      when 'post'
        commentable.title
      when 'clipping'
        commentable.description || "Clipping from #{commentable.user.full_name}"
      when 'photo'
        commentable.description || "Photo from #{commentable.user.full_name}"
      when 'video_asset'
      commentable.title || (commentable.team_id ? "Video from #{commentable.team_name}" : "Video from #{commentable.league_name}")
      when 'video_clip'
        "Clip from #{commentable.user.full_name}"
      when 'video_reel'
        "Reel from #{commentable.user.full_name}"
    end
  end
  
end
