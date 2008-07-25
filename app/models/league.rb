class League < ActiveRecord::Base

  has_many :video_assets
  has_many :teams
  has_many :users, :through => :teams, :source => :users
  belongs_to :state
  
  # Every league needs a name
  validates_presence_of :name
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end
  
end
