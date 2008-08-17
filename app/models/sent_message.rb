class SentMessage < ActiveRecord::Base
  
  belongs_to :user, :foreign_key => :from_id

  named_scope :sent_by,
    lambda { |user| { :conditions => ["from_id = ?",user.id] } }


  # "1/2/3" => [1,2,3]
  def to_ids_array
    return self.to_ids.split('/').collect(&:to_i)
  end

  # [1,2,3] => "1/2/3"
  def to_ids_array=(ary)
    self.to_ids= ary.to_param
  end

  def to_ids_user_names_array
    users = User.find(:all, :conditions => ["id IN (?)", to_ids_array])
    users.inject([]) { |a,u| a << u.full_name}
  end

  
end
