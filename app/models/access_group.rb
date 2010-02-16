class AccessGroup < ActiveRecord::Base
  
  belongs_to :team
  belongs_to :parent, :class_name=>'AccessGroup'
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :access_items
  has_many :access_users
  has_many :access_contacts
  
  validates_presence_of :name
  validates_presence_of :team_id
    
  named_scope :for_team,
    lambda { |team| {:conditions => {:team_id=>team.id, :enabled=>true}, :include => [:team] } }

  named_scope :named,
    lambda { |name| {:conditions => {:name=>name, :enabled=>true}} }

  def items()
    access_items.collect(&:item)
  end
  
  def users()
    access_users.collect(&:user)
  end

  def roster()
    RosterEntry.roster(id)
  end

  def contacts()
    access_contacts
  end
  
  def allow?(user)
    access_users.collect(&:user_id).include? user.id
  end

  def size()
    s = 0
    s += access_contacts.length unless access_contacts.nil?
    s += access_users.length unless access_users.nil?
    s += roster.length unless roster.nil?
    s
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

  def self.for_user(user)
    group_ids = Array.new
    group_ids << AccessUser.for_user(user).collect(&:access_group_id)
    group_ids << RosterEntry.for_user(user).collect(&:access_group_id)
    group_ids = group_ids.flatten.compact.uniq
    AccessGroup.find(group_ids) unless group_ids.empty?
  end
  
end
