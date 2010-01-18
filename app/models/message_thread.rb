class MessageThread < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :from_id
  has_many :sent_messages, :foreign_key => 'thread_id', :order => 'created_at ASC'
  has_many :messages, :foreign_key => 'thread_id', :order => 'created_at ASC'
  
  attr_protected :to_ids, :to_name, :to_email

  def sender()
    return @sender if @sender
    @sender = User.find from_id.to_i
  end
  
  def size()
    self.sent_messages.size
  end
    
  def unread_count(user)
    messages.unread(user.id).size
  end
  
  def to_name=(full_name)
    fn,ln = full_name.split(' ')
    u = User.find(:first, :conditions => ['firstname = ? and lastname = ?',fn,ln])
    if u
      puts "Found user id #{u.id} from full name #{full_name}"
      self.to_id= u.id 
    else
      puts "No user found for #{full_name}"
    end
  end

  def to_name
    users = User.find(:all, :conditions => ["id IN (?)", to_ids_array])
    if users && users.size > 0
      ary = users.inject([]) { |a,u| a << u.full_name}
      return ary.join(", ")
    else
      return ''
    end
    # support for external email addresses
    #self.to_id? ? User.find(self.to_id).full_name : to_email
  end
  
  # Useful for grabbing a set of names and aliases from the 
  # compose form and generating a list of ids that the message
  # gets sent to.
  # NOTE: does not check against access groups, but this may be something
  #  we want to add later. It would require an update to the ajax auto-complete, too.
  def self.get_message_recipient_ids(names,current_user,use_alias_id= false)
    recipient_ids = []
    is_alias = false
    to_names = names.split(',')
    friend_ids = current_user.mail_target_ids() #accepted_friendships.collect(&:friend_id)
    to_names.each do |recipient|
      if recipient == 'all' && current_user.admin?
        if (use_alias_id)
          recipient_ids << Message.alias_id(recipient)
        else
          users = User.find(:all,:conditions => ['enabled = ?',true])
          users.each { |user| recipient_ids << user.id }
          is_alias = true
        end
      elsif recipient == 'team' && current_user.team_staff?
        if (use_alias_id)
          recipient_ids << Message.alias_id(recipient)
        else
          users = User.find(:all, :conditions => ['team_id = ? and enabled = ?',current_user.team_id,true])
          users.each { |user| recipient_ids << user.id }
          is_alias = true
        end
      elsif recipient == 'league' && current_user.league_staff?
        if (use_alias_id)
          recipient_ids << Message.alias_id(recipient)
        else
          users = User.find(:all, :conditions => ['league_id = ? and enabled = ?',current_user.league_id,true])
          users.each { |user| recipient_ids << user.id }
          is_alias = true
        end
      else # normal case, one of current_user's friendships
        fn,ln = recipient.split(' ')
        if (current_user.admin?)
          user = User.find(:first,
                           :conditions => ['firstname = ? and lastname = ? and enabled = ?',
                                           fn,ln,true])
        else
          user = User.find(:first,
                           :conditions => ['firstname = ? and lastname = ? and id in (?) and enabled = ?',
                                           fn,ln,friend_ids,true])
        end
        recipient_ids << user.id if user
      end
    end
    [recipient_ids,is_alias]
  end
 
  def self.get_message_emails(email_str)
    to_emails = []
    emails = email_str.split(',')
    emails.each do |email|
      # validate the email
      email.strip!
      unless /^([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})$/.match(email)
        logger.error "Invalid email address #{email}"
      else
        to_emails << email
      end
    end
    to_emails
  end 

  def external_email_ok?
    !shared_item_id.nil?
  end
  
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
  
  def to_email
    to_emails
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

  def recipient_display_array(from_user=nil)
    ary = Array.new
    
    unless to_ids_array.nil?    
      users = User.find(:all, :conditions => ["id IN (?)", to_ids_array]) 
    end

    if from_user
      unless self.from_id == from_user.id
        unless users.nil?
          # remove this "from_user" from the list of recipients
          users = users.delete_if {|user| user.id == from_user.id}
          # add the original thread sender to the start of the list
          users = users.insert(0,sender())
        else
          users = Array.new
          users << sender()
        end
      end
    end
    
    unless users.nil?
      ary = users.inject([]) { |a,u| a << u.full_name}
    end

    if to_access_group_ids
      groups = AccessGroup.find(to_access_group_ids_array)
      groups.each {|group| ary.insert(0, group.name)}
    end

    if to_ids
      ary.insert(0, 'all') if to_ids.index('-1')
      ary.insert(0, 'team') if to_ids.index('-2')
      ary.insert(0, 'league') if to_ids.index('-3')
    end
    
    if to_emails
      ary << to_emails_array
    end 

    ary
 end 
 
end
