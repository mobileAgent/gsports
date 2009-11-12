class AccessGroup < ActiveRecord::Base
  
  belongs_to :team
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :access_items
  has_many :access_users
  has_many :access_contacts
  
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

  def contacts()
    access_contacts
  end


  
  def allow?(user)
    access_users.collect(&:user_id).include? user.id
  end

  def self.allow_access?(user, item)
    debugger
    access_items = AccessItem.for_item(item)
    if access_items.any?
      access_pass = false
      logger.info("has_access? #{access_pass}")
      access_items.each(){ |access_item|
        access_pass = true if (access_item.access_group.enabled && access_item.access_group.allow?(user) )
        logger.info("has_access? #{access_pass} on access group #{access_item.access_group_id} item #{access_item.id}")
      }
    end
    access_pass
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

  def long_name
    "#{name} for #{team_name}"
  end
  
  
end
