class RosterEntry < ActiveRecord::Base

  belongs_to :access_group
  belongs_to :user

  attr_reader :send_invite
  attr_writer :send_invite

  validates_presence_of :access_group

  before_destroy { |item| AccessUser.for(item.user, item.access_group).destroy_all }

  named_scope :roster,
    lambda { |p_access_group_id| {:conditions => {:access_group_id=>p_access_group_id} } }

  def team_sport()
    TeamSport.for_access_group_id(access_group_id).first
  end

  def match_users()
    User.find(:all, :conditions=>{:team_id=>access_group.team_id, :firstname=>firstname, :lastname=>lastname})
  end

  def full_name()
    "#{firstname} #{lastname}".squeeze.strip
  end
end
