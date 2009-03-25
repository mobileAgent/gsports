class AccessUser < ActiveRecord::Base

  belongs_to :access_group
  belongs_to :user

  def x_validate
    unless user.team_id == access_group.team_id
      errors.add(:thumb_span, "User is not a member of the team that owns this Access Group.")
    end
  end  
   
   

  def self.access_for user
    access = nil
    au = AccessUser.find :first, :conditions=>{ :user_id => user.id }
    access = au.access_group if au
    access
  end
 
end