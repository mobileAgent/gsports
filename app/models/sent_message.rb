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

  # [1,2,3] => "1/2/3"
  def to_access_group_ids_array=(ary)
    logger.debug("assign to_access_group_ids array: #{ary.join(',')}")
    
    self.to_access_group_ids= ary.to_param unless ary.nil?
  end

  def to_access_group_id=(id)
    self.to_access_group_ids= id.to_s unless id.nil?
  end

  # "1/2/3" => [1,2,3]
  def to_access_group_ids_array
    logger.debug("to_access_group_ids: #{to_access_group_ids}")
    
    return self.to_access_group_ids.split('/').collect(&:to_i) unless to_access_group_ids.nil?
  end

  def recipient_display_array
        
    users = User.find(:all, :conditions => ["id IN (?)", to_ids_array])
    ary = users.inject([]) { |a,u| a << u.full_name}

    if to_access_group_ids
      groups = AccessGroup.find(to_access_group_ids_array)
      groups.each {|group| ary.insert(0, group.name)}
    end

    ary.insert(0, 'all') if to_ids.index('-1')
    ary.insert(0, 'team') if to_ids.index('-2')
    ary.insert(0, 'league') if to_ids.index('-3')

    if to_emails
      ary << to_emails_array
    end 

    ary
 end 

  
end
