class Message < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :body
  validates_presence_of :to_id
  validates_presence_of :from_id
  belongs_to :user, :foreign_key => 'to_id'

  attr_protected :to_ids, :to_name

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
    count(:conditions => ["to_id = ? and 'read' = ?", user.id,false])
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

end
