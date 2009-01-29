require 'vendor/plugins/community_engine/app/models/post'

class Post < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :league
  
  named_scope :admin_team_headers, 
        :conditions=>['users.role_id = ? and category_id = ?', Role[:admin].id, ADMIN_TEAM_HEADER_CATEGORY], :include=>:user, :order=>'posts.created_at desc'
  
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
  def self.orig_highlighted_articles(exclude_ids=[-1])
    if exclude_ids.size == 0
      exclude_ids = [-1]
    end
    p = Post.find(:all,
                  :conditions => ["published_as = ? AND id NOT IN (?)","live",exclude_ids],
                  :order => 'view_count desc, favorited_count desc, published_at desc',
                  :limit => 2)
  end
  
  # Return the two most recently admin favorited articles for the home page
  # That aren't already being used as athletes of the week
  def self.highlighted_articles(exclude_ids=[-1])
    if exclude_ids.size == 0
      exclude_ids = [-1]
    end
    f = Favorite.find(:all,
                      :conditions => ["user_id = ? and favoritable_type = ? and favoritable_id NOT IN (?)",
                                      User.admin.first.id,Post.to_s,exclude_ids],
                      :order => 'created_at DESC',
                      :limit => 2)
    f.collect(&:favoritable)
  end
  
  def image_thumbnail_for_post(size = "feature", fallback_to_author = false)
    return '' if self.post.nil?
    img = first_image_in_body()
    if img
      # chaange the size fromw whatever it was to :feature size
      img.gsub!(/_[a-z]+\.([^\.]+)$/,"_#{size}.\\1")
      img.gsub!(/^http:\/\/[^\/]+/,'') # make relative
    elsif fallback_to_author
      img = user.avatar_photo_url(size.to_sym)        
    end
    
    if img.nil?
      img = logo_image_for_post(size)
    end
    img
  end

  # Team or league logo of the author
  def logo_image_for_post(size="feature")
    if user.league_staff? || user.admin? 
      league = League.find(user.league_id)
      if league.avatar
        return league.avatar.public_filename(size.to_sym)
      end
    end
    if (user.team_id && user.team.avatar)
      return user.team.avatar.public_filename(size.to_sym)
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
