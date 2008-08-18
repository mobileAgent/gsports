class SentMessage < ActiveRecord::Base
  
  belongs_to :user, :foreign_key => :from_id
  
  attr_protected :to_name

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
    ary = users.inject([]) { |a,u| a << u.full_name}
    ary << 'all' if to_ids.index('-1')
    ary << 'team' if to_ids.index('-2')
    ary << 'league' if to_ids.index('-3')
    ary
  end

  
end
