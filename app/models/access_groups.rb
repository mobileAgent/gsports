class AccessGroup < ActiveRecord::Base
  
  belongs_to :team
  
  #has_many :channel_video, as => :video #,, :dependent => :destroy
  
  has_many :access_items
  has_many :access_users
  
  def items()
    access_items
  end
  
  def users()
    access_users
  end
  
end
