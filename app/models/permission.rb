class Permission < ActiveRecord::Base

#      user can edit team
#      <blessed> CAN <role> FOR <scope>

  validates_presence_of :role

  belongs_to :blessed, :polymorphic => true
  validates_presence_of :blessed_type
  validates_presence_of :blessed_id

  belongs_to :scope, :polymorphic => true
  validates_presence_of :scope_type
  validates_presence_of :scope_id

  validates_uniqueness_of :role, :scope => [:blessed_type, :blessed_id, :scope_type, :scope_id], :message => 'already exists in this scope.'


  #common roles
  
  EDIT_TEAM_PAGE    = 'ED_TEAMPAGE'
  MANAGE_CHANNELS   = 'MN_CHAN'
  MANAGE_GROUPS     = 'MN_GRP'
  CREATE_STAFF      = 'CR_STAFF'
  UPLOAD            = 'UPLOAD'



  def self.staff_permission_list
    [
      [Permission::EDIT_TEAM_PAGE, 'Edit Team Page'],
      [Permission::MANAGE_CHANNELS, 'Manage Embeddable Channel Player'],
      [Permission::MANAGE_GROUPS, 'Manage Access Groups'],
      [Permission::CREATE_STAFF, 'Create Team Staff'],
      [Permission::UPLOAD, 'Upload Videos']
    ]
  end




  named_scope :for_entity, lambda { |blessed| { :conditions => {:blessed_type=>blessed.class.name, :blessed_id=>blessed.id} }  }
  named_scope :has_role,   lambda { |role|    { :conditions => {:role=>role} }  }
  named_scope :in_scope,   lambda { |scope|   { :conditions => {:scope_type=>scope.class.name, :scope_id=>scope.id} }   }




  def self.grant(blessed, role, scope)
    if !self.check(blessed, role, scope)
      p = Permission.new()
      p.blessed = blessed
      p.role = role
      p.scope = scope
      p.save!
    end
  end


  def self.revoke(blessed, role, scope)
    p = self.check(blessed, role, scope)
    p.destroy if p
  end


  def self.check(blessed, role, scope=nil)
    plist = for_entity(blessed).has_role(role)
    return plist.in_scope(scope).first if scope
    !plist.empty?
  end

  def self.range(blessed, role)
    for_entity(blessed).has_role(role).collect(&:scope)
  end




  
  def to_perm_s
    "#{blessed_type}(#{blessed_id}) CAN #{role} ON #{scope_type}(#{scope_id})"
  end

end