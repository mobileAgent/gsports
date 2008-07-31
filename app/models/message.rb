class Message < ActiveRecord::Base

  validates_presence_of :title
  validates_presence_of :body
  validates_presence_of :to_id
  validates_presence_of :from_id
  
  def self.unread(user)
    count(:conditions => ["to_id = ?", user.id])
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
  
  def self.sent(user)
    msgs = []
    begin
      msgs = find(:all, :conditions => ["from_id = ?", user.id], :order => "created_at DESC")
    rescue Exception => e
        #none
    end
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
