class Message < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :body
  validates_presence_of :to_id
  validates_presence_of :from_id
  belongs_to :user, :foreign_key => :to_id

  attr_protected :to_ids, :to_name
  
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
    msgs = []
    #begin
      msgs = find(:all, :conditions => ["to_id = ?", user.id], :order => "created_at DESC")
    #rescue Exception => e
      #none
    #end
    msgs
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
    friend_ids = current_user.accepted_friendships.collect(&:friend_id)
    is_alias = false
    to_names = names.split(',')
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
          users = User.find(:all, :conditions => ['team_id = ?',current_user.team_id])
          users.each { |user| recipient_ids << user.id }
          is_alias = true
        end
      elsif recipient == 'league' && current_user.league_staff?
        if (use_alias_id)
          recipient_ids << Message.alias_id(recipient)
        else
          users = User.find(:all, :conditions => ['league_id = ?',current_user.league_id])
          users.each { |user| recipient_ids << user.id }
          is_alias = true
        end
      else # normal case, one of current_user's friendships
        fn,ln = recipient.split(' ')
        user = User.find(:first,
                         :conditions => ['firstname = ? and lastname = ? and id in (?)',
                                         fn,ln,friend_ids])
        recipient_ids << user.id if user
      end
    end
    [recipient_ids,is_alias]
  end

  def unread?
    ! read
  end

end
