require 'vendor/plugins/community_engine/app/models/post'

class Post < ActiveRecord::Base

  # set indexes for sphinx
  define_index do
    indexes published_at, :sortable => true
    indexes [user.firstname, user.lastname], :as => :author, :sortable => true
    indexes title
    indexes raw_post
    indexes tags.name, :as => :tags_content
    indexes category.name, :as => :category_name
    indexes published_as # can't be used as an attr
    set_property :delta => true
   end

  def image_thumbnail_for_post
    return nil if self.post.nil?
    img = first_image_in_body()
    if img
      # chaange the size fromw whatever it was to :thumb size
      img.gsub!(/_[a-z]+\.jpg/,'_thumb.jpg')
    else
      nil
    end
  end
  
  
end
