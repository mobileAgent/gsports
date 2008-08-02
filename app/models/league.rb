class League < ActiveRecord::Base

  has_many :video_assets
  has_many :teams
  has_many :users, :through => :teams, :source => :users
  belongs_to :state
  belongs_to :avatar, :class_name => "Photo", :foreign_key => "avatar_id"
  
  # Every league needs a name
  validates_presence_of :name

  alias_method :league_avatar, :avatar
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end
  
  def state_name
    state ? state.name : nil
  end
  
end
