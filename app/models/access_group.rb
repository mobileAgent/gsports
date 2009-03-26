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
    access_items.collect(&:item)
  end
  
  def users()
    access_users.collect(&:user)
  end
  
  def allow?(user)
    access_users.collect(&:user_id).include? user.id
  end
    
  def team_name= name
    team = Team.find(:first, :conditions=>{ :name=>name })
    team_id = team.id if team
  end
  
  def team_name
    if team_id
      team = Team.find(team_id)
      team ? team.name : '' rescue '!'
    end
  end
  
  
end
