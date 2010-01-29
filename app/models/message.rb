class Message < ActiveRecord::Base

  validates_presence_of :to_id #, :unless => :external_email_present?
  validates_presence_of :sent_message_id
  validates_presence_of :thread_id
  belongs_to :sent_message, :foreign_key => :sent_message_id
  belongs_to :message_thread, :foreign_key => :thread_id
  belongs_to :user, :foreign_key => :to_id
  belongs_to :access_group, :foreign_key => :to_access_group_id
    
  # prototype sql was: select id, thread_id, title, from_id, to_id, count(*) from messages  where to_id = 9 group by ifnull(thread_id, id) ;
  # it would be ideal to pick up the reply count as above
  # this has an issue of picking the first message in the thread.  attempts to group on an produce the latest item have been futile
  named_scope :user_threads, lambda { |user_id| { :conditions => ["deleted = 0 AND to_id = ?", user_id], :group => "thread_id" } }
  
  named_scope :message_thread, lambda { |thread| { :conditions => ["deleted = 0 AND thread_id = ?", thread.id ] } }

  named_scope :for_user, lambda { |user_id| { :conditions => ["deleted = 0 AND to_id = :me", { :me => user_id } ] } }
  
  named_scope :unread, lambda { |user_id| { :conditions => ['deleted = 0 AND `read` = 0 AND to_id = :me', { :me => user_id} ] } }
    
  def self.unread(user)
    count(:conditions => ["deleted = 0 AND to_id = ? and messages.read = ?", user.id,false])
  end
  
  def self.inbox(user)
    user_threads(user.id).all(:order => "created_at DESC")
  end

  def unread?
    !self.read
  end
  
  def sender()
    return self.sent_message.sender
  end
  
  def recipient()
    return @recipient if @recipient
    if to_id
      @recipient = User.find to_id.to_i
    elsif to_email
      # support for external email addresses
      @recipient = User.new :email => to_email
    elsif to_access_group_id
      # support for access groups
      group = AccessGroup.find :to_access_group_id
      unless group.nil?
        @recipient = User.new :last_name => "Group: #{group.name}"
      end
    end
  end
  
  def sent_on_display(format = "%Y/%m/%d")
     created_at.strftime(format)
  end
end
