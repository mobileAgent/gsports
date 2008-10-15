class Message < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :body
  validates_presence_of :to_id
  validates_presence_of :from_id
  belongs_to :user, :foreign_key => :to_id
  
  
  attr_protected :to_ids, :to_name
  
  # prototype sql was: select id, thread_id, title, from_id, to_id, count(*) from messages  where to_id = 9 group by ifnull(thread_id, id) ;
  # it would be ideal to pick up the reply count as above
  # this has an issue of picking the first message in the thread.  attempts to group on an produce the latest item have been futile
  named_scope :user_threads, lambda { |user_id| { :conditions => ["to_id = ?", user_id], :group => "ifnull(thread_id, id)" } }
  
  named_scope :message_thread, lambda { |message| { :conditions => ["ifnull(thread_id, id) = ?", message.real_thread_id ] } }
  
  named_scope :owned_by, lambda { |user_id| { :conditions => ["from_id = :me OR to_id = :me", { :me => user_id } ] } }
  
  named_scope :unread, lambda { |user_id| { :conditions => ['`read` = 0 AND to_id = ?', user_id ] } }
  
  
  def real_thread_id
    thread_id || id
  end
  
  def self.alias_name(id)
    case id 
    when -1
      'all'
    when -2
      'team'
    when-3
      'league'
    end
  end

  def self.alias_id(name)
    case name
    when 'all'
      -1
    when 'team'
      -2
    when 'league'
      -3
    end
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
    self.to_id? ? User.find(self.to_id).full_name : nil
  end
  
  def self.unread(user)
    count(:conditions => ["to_id = ? and messages.read = ?", user.id,false])
  end
  
  def self.inbox(user)
    user_threads(user.id).all(:order => "created_at DESC")
  end
  
  def sender()
    return @sender if @sender
    @sender = User.find from_id.to_i
  end
  
  def recipient()
    return @recipient if @recipient
    @recipient = User.find to_id.to_i
  end
  
  def sent_on_display(format = "%Y/%m/%d")
     created_at.strftime(format)
  end

  # Useful for grabbing a set of names and aliases from the 
  # compose form and generating a list of ids that the message
  # gets sent to.
  def self.get_message_recipient_ids(names,current_user,use_alias_id= false)
    recipient_ids = []
    is_alias = false
    to_names = names.split(',')
    friend_ids = current_user.accepted_friendships.collect(&:friend_id)
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
  

  def unread?
    ! read
  end

end
