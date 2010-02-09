class AccessUser < ActiveRecord::Base

  belongs_to :access_group
  belongs_to :user

  validates_presence_of :user_id
  
  validates_uniqueness_of :user_id, :scope => [:access_group_id], :message => 'has already been added to this group.'


  named_scope :for, lambda { |user, access_group|
      { :conditions=>{:user_id=>user.id, :access_group_id=>access_group.id} }
  }

  def self.access_for user
    access = nil
    au = AccessUser.find :first, :conditions=>{ :user_id => user.id }
    access = au.access_group if au
    access
  end
 
end