class MessageThread < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :from_id
  has_many :sent_messages, :foreign_key => 'thread_id', :order => 'created_at ASC'
  has_many :messages, :foreign_key => 'thread_id', :order => 'created_at ASC'

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

  def multiple_recipients?
    recipient_count = 0;

    unless to_ids_array.nil?    
      recipient_count += to_ids_array.size
      return true if recipient_count > 1
    end  

    if to_ids
      # team, league, and "all" aliases are assumed to be multi-recipients
      return true if (to_ids.index('-1') || to_ids.index('-2') || to_ids.index('-3'))
    end
    
    if to_emails
      recipient_count += to_emails_array.size
      return true if recipient_count > 1
    end 
      
    if to_phones
      recipient_count += to_phones_array.size
      return true if recipient_count > 1
    end
  
    unless to_access_group_ids.nil?
      groups = AccessGroup.find(to_access_group_ids_array)
      groups.each do |group| 
        recipient_count += group.contacts.size
        return true if recipient_count > 1
      end
    end
  
    return false  
  end
  
  def to=(entries_csv)
  end
  
  def to
    return recipient_display_array(nil).join(', ')
  end

  def to_id=(user_id)
    logger.debug "Setting to_id for user #{user_id}"
    self.to_ids= user_id.to_s
    logger.debug "#{to_ids}"
  end
      
  # Useful for grabbing a set of names and aliases from the 
  # compose form and generating a list of ids that the message
  # gets sent to.
  # NOTE: does not check against access groups, but this may be something
  #  we want to add later. It would require an update to the ajax auto-complete, too.
  def self.get_message_recipient_ids(names,current_user,use_alias_id= false)
    recipient_ids = []
    is_alias = false
    to_names = Utilities::csv_split(names)
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
    emails = Utilities::csv_split(email_str)
    emails.each do |email|
      # validate the email
      email.strip!
      
      # "simple" email regexp: /^([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})$/
            
      # allow emails in the format
      #  abc@123.com
      #  <abc@123.com>
      #  John Davis <abc@123.com>
      unless /(?:^|^<|(.+) <)([^@\s]+)@((?:[-a-z0-9A-Z]+\.)+[a-zA-Z]{2,})>?$/.match(email)
        logger.error "Invalid email address #{email}"
      else
        to_emails << email
      end
    end
    to_emails
  end 

  def self.get_message_phones(phone_str)
    to_phones = []
    phones = Utilities::csv_split(phone_str)
    phones.each do |sms|
      # validate the number
      sanitized = sms.strip
      sanitized.gsub!(/[^\w]/,'')

      # support 10 digit numbers only
      unless /^\d{10}$/.match(sanitized)
        logger.error "Invalid phone number #{sms}"
      else
        to_phones << sanitized
      end
    end
    to_phones
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

  # [x@y.z,a@b.c,h@j.k] => "x@y.z/a@b.c/h@j.k"
  def to_emails_array=(ary)
    self.to_emails= ary.to_param unless ary.nil?
  end

  # "x@y.z/a@b.c/h@j.k" => [x@y.z,a@b.c,h@j.k]
  def to_emails_array
    return self.to_emails.split('/').collect unless to_emails.nil?
  end

  # [x@y.z,a@b.c,h@j.k] => "x@y.z/a@b.c/h@j.k"
  def to_phones_array=(ary)
    self.to_phones= ary.to_param unless ary.nil?
  end

  # "x@y.z/a@b.c/h@j.k" => [x@y.z,a@b.c,h@j.k]
  def to_phones_array
    return self.to_phones.split('/').collect unless to_phones.nil?
  end

  # [1,2,3] => "1/2/3"
  def to_access_group_ids_array=(ary)
    logger.debug("assign to_access_group_ids array: #{ary.join(',')}")
    
    self.to_access_group_ids= ary.to_param unless ary.nil?
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
    
    unless to_emails_array.nil?
      ary << to_emails_array
    end 
    
    unless to_phones_array.nil?
      to_phones_array.each do |phone|
        ary << Utilities::readable_phone(phone)
      end
    end

    ary
  end 
end
