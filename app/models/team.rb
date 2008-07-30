class Team < ActiveRecord::Base

  has_many :video_assets
  belongs_to :league
  has_many :users
  belongs_to :avatar, :class_name => "Photo", :foreign_key => "avatar_id"

  # Every team needs a name and a league
  validates_presence_of :name
  validates_presence_of :league_id

  delegate :league_avatar, :to => :league
  
  alias_method :team_avatar, :avatar
  
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end
  
end
