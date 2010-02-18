
require 'digest/sha1'

class RosterEntry < ActiveRecord::Base

  belongs_to :access_group
  belongs_to :user

  has_many :parents

  validates_presence_of :access_group


  before_destroy { |item| AccessUser.for(item.user, item.access_group).destroy_all if item.user }
  before_destroy { |item| item.parents.destroy_all }

  named_scope :roster,
    lambda { |p_access_group_id| {:conditions => {:access_group_id=>p_access_group_id} } }

  named_scope :for_user,
    lambda { |user| {:conditions => {:user_id=>user.id} } }



  attr_reader :send_invite
  attr_writer :send_invite
#  def send_invite=(value)
#    @send_invite=value
#  end

  def share()
    self.reg_key= Digest::SHA1.hexdigest("#{RosterEntry}+id.to_s")
  end

  named_scope :for_invite_key, lambda { |key| { :conditions=>{:reg_key=>key} }  }


  def team_sport()
    TeamSport.for_access_group_id(access_group_id).first
  end

  def match_users()
    User.find(:all, :conditions=>{:team_id=>access_group.team_id, :firstname=>firstname, :lastname=>lastname})
  end

  def full_name()
    "#{firstname} #{lastname}".squeeze(' ').strip
  end






end
