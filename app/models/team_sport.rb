class TeamSport < ActiveRecord::Base

  belongs_to :team
  belongs_to :access_group


  #TODO create access group on save if nil

  named_scope :for, lambda { |team, sport_name| {:conditions=>{:team_id => team.id, :name => sport_name}}  }

end