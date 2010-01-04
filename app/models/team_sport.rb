class TeamSport < ActiveRecord::Base

  belongs_to :team
  belongs_to :access_group

  #before_save :check_access_group

  #TODO create access group on save if nil

  named_scope :for, lambda { |team, sport_name| {:conditions=>{:team_id => team.id, :name => sport_name}}  }



  def setup_access_groups(user)

    group = AccessGroup.for_team(team).named(name).first
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
      
      access_group = group

      subgroup = AccessGroup.new()
      subgroup.team = team
      subgroup.name = "#{name} Staff"
      subgroup.enabled = true
      subgroup.save!

      subaccess = AccessUser.new()
      subaccess.access_group = subgroup
      subaccess.user = user
      subaccess.save!
    end


  end


end