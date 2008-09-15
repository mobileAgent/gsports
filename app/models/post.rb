require 'vendor/plugins/community_engine/app/models/post'

class Post < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :league
  
  # set indexes for sphinx
  define_index do
    indexes published_at, :sortable => true
    indexes [user.firstname, user.lastname], :as => :author, :sortable => true
    indexes title
    indexes raw_post
    indexes tags.name, :as => :tags_content
    indexes category.name, :as => :category_name
    indexes published_as # can't be used as an attr
    # This causes sphinx indexing to crawl. Need to figure out why
    # before enabling it
    #indexes comments.comment, :as => :comment_comments
    set_property :delta => true
   end

  # Return the two most viewed/favorited articles for the home page
  # That aren't already being used as athletes of the week
  def self.highlighted_articles(exclude_ids=[-1])
    p = Post.find(:all,
                  :conditions => ["published_as = ? AND id NOT IN (?)","live",exclude_ids],
                  :order => 'view_count desc, favorited_count desc, published_at desc',
                  :limit => 2)
  end
  
  def image_thumbnail_for_post(size = "feature")
    return '' if self.post.nil?
    img = first_image_in_body()
    if img
      # chaange the size fromw whatever it was to :feature size
      img.gsub!(/_[a-z]+\.jpg/,"_#{size}.jpg")
      img.gsub!(/^http:\/\/[^\/]+/,'') # make relative
    else
      img = logo_thumbnail_for_post
    end
    img
  end

  # Team or league logo of the author
  def logo_thumbnail_for_post
    if user.league_staff? || user.admin? 
      league = League.find(user.league_id)
      if league.avatar
        return league.avatar.public_filename(:thumb)
      end
    end
    if (user.team_id && user.team.avatar)
      return user.team.avatar.public_filename(:thumb)
    else
      return ''
    end
  end

  # Team or league name of the author
  def logo_title
    if self.user.league_staff?
      self.user.league.name
    else
      self.user.team_name
    end
  end
  
end
