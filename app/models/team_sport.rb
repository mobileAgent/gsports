class TeamSport < ActiveRecord::Base

  belongs_to :team
  belongs_to :access_group

  before_save :check_access_group

  #TODO create access group on save if nil

  named_scope :for, lambda { |team, sport_name| {:conditions=>{:team_id => team.id, :name => sport_name}}  }



  def check_access_group

    group = AccessGroup.for_team(team).named(name).first
    if !group
      group = AccessGroup.new()
      group.team = team
      group.name = name
      group.enabled = true
      group.save!
      access_group = group
    end


  end


end