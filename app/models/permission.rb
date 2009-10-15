class Permission < ActiveRecord::Base

  belongs_to :access_group

  validates_presence_of :name

  belongs_to :grant, :polymorphic => true
  validates_presence_of :grant_type
  validates_presence_of :grant_id

  belongs_to :scope, :polymorphic => true
  validates_presence_of :scope_type
  validates_presence_of :scope_id

  


  validates_uniqueness_of :item_id, :scope => [:item_type,:access_group_id], :message => 'has already been added to this group.'
  validates_uniqueness_of :item_id, :scope => [:item_type], :message => 'has already been added to a group.'


  validates_uniqueness_of :name, :scope => [:grant_type, :grant_id, :scope_type, :scope_id], :message => 'already exists in this scope.'

  

  named_scope :for_item,
    lambda { |item| {:conditions => {:item_id=>item.id, :item_type=>item.class.name} } }


  def validate
    #This is VideoAsset specific
#    if (item === VideoAsset ) && item.team_id != access_group.team_id
#      errors.add(:access_group_id, "User is not a member of the team that owns this Access Group.")
#    end
  end

  def self.restriction_for item
    restrict = nil
    ai = AccessItem.for_item(item).first
    restrict = ai.access_group if ai
    restrict
  end

  def to_perm_s
    "#{grant_type}(#{grant_id}) CAN #{name} ON #{scope_type}(#{scope_id})"
  end

end