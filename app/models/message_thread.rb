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

    unless to_roster_entry_ids.nil?
      recipient_count += to_roster_entry_ids.size
      return true if recipient_count > 1
    end

    unless to_ids_array.nil?    
      recipient_count += to_ids_array.size
      return true if recipient_count > 1
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
  
  def is_sms?
    (is_sms == true)
  end
  
  # used by form only...
  def to=(entries_csv)
  end
  
  # used by the form
  def to
    s = recipient_display_array(nil).join(', ')
    s += ", " unless s.nil? || s.empty?
    s
  end

  # used by form only... 
  def to_ids_choices=(entries_csv)
  end

  # used by the form
  def to_ids_choices()
    ary = Array.new
    
    unless to_roster_entry_ids_array.nil?
      ary << to_roster_entry_ids_array.collect{ |id| "r#{id}" }
    end
    
    unless to_ids_array.nil?    
      ary << to_ids_array.collect{ |id| "u#{id}" }
    end

    if from_id
      ary << 'u' + from_id
    end
    
    unless to_access_group_ids_array.nil?
      ary << to_access_group_ids_array.collect{ |id| "g#{id}" }
    end
    
    ary.flatten.join(',') unless ary.empty?
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
  def self.get_message_recipient_ids(names,current_user)
    recipient_ids = []
    is_alias = false
    to_names = Utilities::csv_split(names)
    friend_ids = current_user.mail_target_ids() #accepted_friendships.collect(&:friend_id)
    to_names.each do |recipient|
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
    recipient_ids
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

  # "1/2/3" => [1,2,3]
  def to_roster_entry_ids_array
    return self.to_roster_entry_ids.split('/').collect(&:to_i) unless to_roster_entry_ids.nil?
  end

  # [1,2,3] => "1/2/3"
  def to_roster_entry_ids_array=(ary)
    self.to_roster_entry_ids= ary.to_param unless ary.nil?
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
    self.to_access_group_ids= ary.to_param unless ary.nil?
  end

  # "1/2/3" => [1,2,3]
  def to_access_group_ids_array
    return self.to_access_group_ids.split('/').collect(&:to_i) unless to_access_group_ids.nil?
  end

  def recipient_display_array(from_user=nil)
    ary = Array.new
    
    unless to_roster_entry_ids_array.nil?
      roster_entries = RosterEntry.find(:all, :conditions => ["id IN (?)", to_roster_entry_ids_array])
      ary << roster_entries.collect { |r| r.full_name }
    end
    
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
      ary << users.collect{ |u| u.full_name }
    end

    if to_access_group_ids
      groups = AccessGroup.find(to_access_group_ids_array)
      groups.each {|group| ary.insert(0, group.name)}
    end
    
    unless to_emails_array.nil?
      ary << to_emails_array
    end 
    
    unless to_phones_array.nil?
      ary << to_phones_array.collect{ |phone| Utilities::readable_phone(phone) }
    end

    ary.flatten
  end 


end
