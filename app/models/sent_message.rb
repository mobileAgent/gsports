class SentMessage < ActiveRecord::Base
  
  belongs_to :user, :foreign_key => :from_id
  belongs_to :shared_access
  
  attr_protected :to_name

  named_scope :sent_by,
    lambda { |user| { :conditions => ["from_id = ?",user.id] } }


  # "1/2/3" => [1,2,3]
  def to_ids_array
    return self.to_ids.split('/').collect(&:to_i) unless to_ids.nil?
  end

  # [1,2,3] => "1/2/3"
  def to_ids_array=(ary)
    self.to_ids= ary.to_param unless ary.nil?
  end

  def to_id=(id)
    self.to_ids= id.to_s unless id.nil?
  end

  # [x@y.z,a@b.c,h@j.k] => "x@y.z/a@b.c/h@j.k"
  def to_emails_array=(ary)
    self.to_emails= ary.to_param unless ary.nil?
  end


  # "x@y.z/a@b.c/h@j.k" => [x@y.z,a@b.c,h@j.k]
  def to_emails_array
    return self.to_emails.split('/').collect unless to_emails.nil?
  end

  def to_email=(email)
    self.to_emails= email
  end

  def recipient_display_array
    users = User.find(:all, :conditions => ["id IN (?)", to_ids_array])
    ary = users.inject([]) { |a,u| a << u.full_name}
    ary << 'all' if to_ids.index('-1')
    ary << 'team' if to_ids.index('-2')
    ary << 'league' if to_ids.index('-3')

    if to_emails
      ary << to_emails_array
    end 

    ary
 end 

  
end
