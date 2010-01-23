class SentMessage < ActiveRecord::Base
  
  validates_presence_of :thread_id
  belongs_to :message_thread, :foreign_key => :thread_id
  has_many :messages
  belongs_to :user, :foreign_key => :from_id
  belongs_to :shared_access
  
  named_scope :sent_by,
    lambda { |user| { :conditions => ["from_id = ?",user.id] } }

  named_scope :sent_threads, 
    lambda { |user| { :conditions => ["owner_deleted = 0 AND from_id = ?", user.id], :group => "thread_id" } }

  def sender()
    return @sender if @sender
    @sender = User.find self.from_id.to_i
  end

  def is_thread_start() 
    if (self.message_thread.from_id == self.from_id) 
      return id == self.message_thread.sent_messages[0].id
    end
    return false
  end
  
  def user_message(user)
    messages.find(:first, :conditions => { :sent_message_id => id, :user_id => user.id })
  end
  
  def sent_on_display(format = "%Y/%m/%d ")
   created_at.strftime(format)
  end
  
end
