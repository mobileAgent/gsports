class ReportDetail < ActiveRecord::Base


  belongs_to :report

  belongs_to :video, :polymorphic => true

  belongs_to :post

  validates_presence_of :video_type
  validates_presence_of :video_id





  validates_uniqueness_of :item_id, :scope => [:item_type,:access_group_id], :message => 'has already been added to this group.'
  validates_uniqueness_of :item_id, :scope => [:item_type], :message => 'has already been added to a group.'

  named_scope :for_item,
    lambda { |item| {:conditions => {:item_id=>item.id, :item_type=>item.class.name} } }


  def validate
    #This is VideoAsset specific
    if (item === VideoAsset ) && item.team_id != access_group.team_id
      errors.add(:access_group_id, "User is not a member of the team that owns this Access Group.")
    end
  end

  def self.restriction_for item
    restrict = nil
    ai = AccessItem.for_item(item).first
    restrict = ai.access_group if ai
    restrict
  end

end