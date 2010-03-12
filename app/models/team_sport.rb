class TeamSport < ActiveRecord::Base

  belongs_to :team
  belongs_to :access_group
  belongs_to :staff_access_group, :class_name => 'AccessGroup'
  belongs_to :avatar, :class_name => "Photo", :foreign_key => "avatar_id"

  before_save :check_access_group

  #TODO create access group on save if nil

  named_scope :for, lambda { |team, sport_name| {:conditions=>{:team_id => team.id, :name => sport_name}}  }

  named_scope :for_access_group_id, lambda { |p_access_group_id| {:conditions=>{:access_group_id => p_access_group_id}}  }

  named_scope :for_team, lambda { |team| { :conditions=>{:team_id=>team.id}} }


  def setup_access_groups(user)

    group = AccessGroup.for_team(team).named(name).first
    subgroup = nil
    
    if !group
      group = AccessGroup.new()
      group.team = team
      group.name = name
      group.enabled = true
      group.save!

      access = AccessUser.new()
      access.access_group = group
      access.user = user
      access.save!
      
      subgroup = AccessGroup.new()
      subgroup.team = team
      subgroup.name = "#{name} Staff"
      subgroup.enabled = true
      subgroup.parent = group
      subgroup.save!

      subaccess = AccessUser.new()
      subaccess.access_group = subgroup
      subaccess.user = user
      subaccess.save!

    end

    self.access_group = group
    self.staff_access_group = subgroup


  end

  def check_access_group
    if self.access_group && self.name != self.access_group.name
      self.access_group.name = self.name
      self.access_group.save
      if self.staff_access_group
        self.staff_access_group.name = "#{self.name} Staff"
        self.staff_access_group.save
      end
    end
  end

  
  def avatar_photo_url(size = nil)
    if avatar
      avatar.public_filename(size)
    else
      case size
        when :thumb
          AppConfig.photo['missing_thumb']
        else
          AppConfig.photo['missing_medium']
      end
    end
  end

  def recipient_list()
#    [
#      "All #{name} team athletes and coaches",
#      "All #{name} team athletes",
#      "All #{name} team coaches",
#      "All #{name} team parents",
#      "All #{name} team athletes and parents",
#      "All #{name} team athletes, coaches and parents"
#    ]
#    [
#      "All #{name} team athletes and coaches",
#      "All #{name} team athletes",
#      "All #{name} team coaches",
#    ]
    [
      ["Athletes and Coaches", 3],
      ["Athletes", 2],
      ["Coaches", 1]
#      ,
#      ["Parents", 4],
#      ["Athletes and Parents", 6],
#      ["Athletes, Coaches and Parents", 7]
    ]
  end

  
end