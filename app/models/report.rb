class Report < ActiveRecord::Base

  belongs_to :owner, :polymorphic => true
  belongs_to :author, :class_name => 'User'    #, :foreign_key => :author_id
  belongs_to :access_group

  has_many :report_details, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :author_id

  # unpublished is ok # validates_presence_of :access_group_id


  named_scope :for_owner, lambda { |owner| { :conditions => {:owner_type=>owner.class.name, :owner_id=>owner.id} }  }

end
