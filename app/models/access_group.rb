class AccessGroup < ActiveRecord::Base
  
  belongs_to :team
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :access_items
  has_many :access_users
  
  validates_presence_of :name
  validates_presence_of :team_id
  
  
  named_scope :for_team,
    lambda { |team| {:conditions => {:team_id=>team.id, :enabled=>true}, :include => [:team] } }

  
  def items()
    access_items
  end
  
  def users()
    access_users
  end
  
end
