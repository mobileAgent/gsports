class RosterEntry < ActiveRecord::Base

  belongs_to :access_group
  belongs_to :user

  attr_reader :send_invite
  attr_writer :send_invite

  validates_presence_of :access_group
  

  named_scope :roster,
    lambda { |p_access_group_id| {:conditions => {:access_group_id=>p_access_group_id} } }

  def team_sport()
    TeamSport.for_access_group_id(access_group_id).first
  end

end
