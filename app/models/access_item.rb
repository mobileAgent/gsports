class AccessItem < ActiveRecord::Base

  belongs_to :access_group
  belongs_to :item, :polymorphic => true


  validates_presence_of :item_type
  validates_presence_of :item_id
  validates_presence_of :acess_group_id
  
  validates_uniqueness_of :item_id, :scope => [:item_type,:acess_group_id], :message => 'has already been added to this group.'
  validates_uniqueness_of :item_id, :scope => [:item_type], :message => 'has already been added to a group.'


end