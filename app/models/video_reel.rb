class VideoReel < ActiveRecord::Base
  
  belongs_to :user
  
  acts_as_commentable
  acts_as_taggable
  has_many :favorites, :as => :favoritable, :dependent => :destroy
  acts_as_activity :user
  
  # Every reel needs a title
  validates_presence_of :title
  
  # set indexes for sphinx
  define_index do
    indexes title, :sortable => true
    indexes description
    indexes updated_at, :sortable => true
    indexes tags.name, :as => :tag_names
    indexes comments.comment, :as => :comment_comments
  end
  
  # For the sake of symmetry
  named_scope :for_user,
    lambda { |user| { :conditions => ["user_id = ?",user.id] } }
  
end
