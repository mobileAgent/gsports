class Team < ActiveRecord::Base

  has_many :video_assets
  belongs_to :league
  has_many :users

  # Every team needs a name
  validates_presence_of :name
  
  def self.find_list(tag_list)
    find(:all, :conditions => [ 'LOWER(name) LIKE ?', '%' + tag_list + '%' ])
  end
  
end
