class ReportDetail < ActiveRecord::Base


  belongs_to :report

  belongs_to :video, :polymorphic => true

  belongs_to :post

  validates_presence_of :video_type
  validate :type_is_allowed

  validates_presence_of :video_id

  validates_uniqueness_of :video_id, :scope => [:video_id, :video_type,:report_id], :message => 'has already been included.'



  AllowedTypes = ['VideoClip', 'VideoReel']


  def type_is_allowed
    errors.add(:video, "Type is not allowed") unless ReportDetail::AllowedTypes.include?(video_type)
  end


  named_scope :for_item,      lambda { |item| {:conditions => {:item_id=>item.id, :item_type=>item.class.name} } }

  named_scope :for_item_type, lambda { |item_type, item_id| {:conditions => {:item_id=>item_id, :item_type=>item_type} } }

  named_scope :for_report,    lambda { |report| { :conditions => {:report_id=>report.id}, :order=>:orderby } }

  def find_video()
    self.video = video_type.constantize.find(video_id) if AllowedTypes.include? video_type
  end


end