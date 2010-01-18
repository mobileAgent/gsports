class MessagesController < BaseController
  
  protect_from_forgery :except => [:auto_complete_for_friend_full_name]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :create ])

  # GET /messages
  # GET /messages.xml
  def index
    @thread_summary = true
    @msgs = Message.user_threads(current_user.id).paginate(:page => params[:page], :order => "created_at DESC")
    render :action => 'inbox'
  end
  
  def thread
    @thread_summary = false   
    @message_thread = MessageThread.find(params[:id].to_i)
    @sent_msgs = @message_thread.sent_messages
    
    # mark as read...
    @message_thread.messages.unread(current_user.id).each do |msg|
      next if msg.read
      msg.read = 1
      msg.save!
    end 
    
    render :action => 'thread'
  end
  
  def thread_read
    thread = MessageThread.find(params[:id].to_i)
    thread.messages.unread(current_user.id).each do |msg|
      next if msg.read
      msg.read = 1
      msg.save!
    end
    
    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

  def thread_unread
    c = 0;
    thread = MessageThread.find(params[:id].to_i)
    thread.messages.unread(current_user.id).each do |msg|
      next if !msg.read
      msg.read = 0
      msg.save!
      c += 1
    end
    if c > 0
      flash[:info] = "#{c > 1 ? c.to_s() + ' messages have' : 'Message has'} been marked unread."
    end    
    
    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

  def thread_delete
    c = 0;
    thread = MessageThread.find(params[:id].to_i)
    thread.messages.for_user(current_user.id).each do |msg|
      next if msg.deleted
      msg.deleted = 1
      msg.save!
      c += 1
    end
    # if the sent=true flag is sent, delete the sent
    # messages by this user
    sent = (params[:sent] && params[:sent] == 'true')
    if sent
      thread.sent_messages.sent_by(current_user).each do |sent|
        next if sent.owner_deleted
        sent.owner_deleted = 1
        sent.save!
        c += 1
      end
    end
    if c > 0
      flash[:info] = "#{c > 1 ? c + ' messages have' : 'Message has'} been deleted."
    end
    
    respond_to do |format|
      format.html { sent ? redirect_to(sent_messages_url) : redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end
  
  
  # GET /messages/new
  def new
    # allow external-only emails to be sent for shared items
    shared_access_id = params[:shared_access_id] || (params[:sent_message] ? params[:sent_message][:shared_access_id] : nil)
    if shared_access_id
      logger.debug("Sharing item: #{shared_access_id}")
      @shared_access = SharedAccess.find(shared_access_id.to_i)
    end

    unless (@shared_access || current_user.admin? || current_user.team_staff? || current_user.league_staff?)
      if current_user.accepted_friendships.size == 0
        flash[:info] = "You need to have some friends to send messages to!"
        redirect_to accepted_user_friendships_path(current_user) and return
      end
    end
    
    @sent_message = SentMessage.new(params[:sent_message])
    logger.debug("built message #{@sent_message.inspect} from params #{params.inspect}")
   
    if params[:re_thread]
      @message_thread = MessageThread.find(params[:re_thread].to_i)
    elsif params[:re]
      #todo: start a new thread if replying to individual message??
      @reply_to = Message.find(params[:re].to_i)
      @message_thread = MessageThread.find(@reply_to.thread_id)
    end
    
    if @message_thread.nil?
      @message_thread = MessageThread.new(params[:thread])
      @message_thread.title = params[:title] if params[:title]
    
      if params[:to]
        begin
          @message_thread.to_name= User.find(params[:to]).full_name
        rescue
          logger.debug("sked for a bad to_id #{params[:to]}")
        end
      end
    end

    if @message_thread && @message_thread.id
      @sent_message.thread_id = @message_thread.id
    elsif
      if @shared_access
        @sent_message.shared_access_id= @shared_access.id
        @shared_item = @shared_access.item
        @message_thread.title = "#{current_user.full_name} sent you #{@shared_access.video? ? 'a video' : 'something'}: \"#{@shared_item.title}\""
      end
    end  
        
    render :action => :new
  end
  
  # GET /messages/new links
  def update
    new
  end

  # POST /messages
  # POST /messages.xml
  def create
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    logger.debug("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    shared_access_id = params[:shared_access_id] || (params[:sent_message] ? params[:sent_message][:shared_access_id] : nil)
    if shared_access_id
      logger.debug("Sharing item: #{shared_access_id}")
      @shared_access = SharedAccess.find(shared_access_id.to_i)
    end

    @sent_message = SentMessage.new(params[:sent_message])

    new_thread = false
    thread_id = params[:message_thread][:id]
    if thread_id
      @message_thread = MessageThread.find(thread_id)
    end
    
    if @message_thread && @message_thread.id
      new_thread = false
      
      # pull out recipients
      recipient_ids = @message_thread.to_ids_array
      
      # add the original sender
      unless @message_thread.from_id == current_user.id
        if recipient_ids.nil?
          recipient_ids = Array.new
        else
          # remove this "from_user" from the list of recipients
          recipient_ids = recipient_ids.delete_if {|id| id == current_user.id}  
        end
        
        # add the original thread sender to the start of the list
        recipient_ids << @message_thread.from_id 
      end
      
      recipient_emails = @message_thread.to_emails_array
      
      if @message_thread.to_access_group_ids_array
        recipient_access_groups = AccessGroup.find(@message_thread.to_access_group_ids_array)
      end
      
    else
      new_thread = true
      @message_thread = MessageThread.new(params[:message_thread])
      
      if (params[:message_thread][:to_name])
        begin
          recipient_ids,is_alias =
            MessageThread.get_message_recipient_ids(params[:message_thread][:to_name], current_user)
        rescue Exception => e
          logger.error "Error parsing friend names: #{e.message}"
        end
      else
        recipient_ids,is_alias = params[:message_thread][:to_id],false
      end
  
      if (params[:message_thread][:to_email])
        begin
          recipient_emails = MessageThread.get_message_emails(params[:message_thread][:to_email])
        rescue Exception => e
          logger.error "Error parsing email addresses: #{e.message}"
        end
      end 
  
      if (params[:to_access_group_id])
        logger.debug("To access group id: #{params[:to_access_group_id].join(',')}")    
        begin
          recipient_access_groups = AccessGroup.find(params[:to_access_group_id])
        rescue Exception => e
          logger.error "Error parsing recipient access groups: #{e.message}"
        end
      end 
  
      #this is a publication message
      report_id = params[:report] ? params[:report][:id] : nil
      if (report_id)
        report = Report.find(report_id)
  
        #access_group_id = params[:access_item][:access_group_id]
        #group = AccessGroup.find(access_group_id);
  
        @access_item = AccessItem.new params[:access_item]
        if @access_item.access_group_id
          @access_item.item = report
          result = @access_item.save
        end
  
        logger.debug("Publish report #{report_id} access group id: #{@access_item.access_group_id}")
  
        #depricated
  #      report.access_group = group
  #      result = report.save
  
        recipient_access_groups = [@access_item.access_group]
      end
  
      
      if (recipient_ids.nil? || recipient_ids.empty?) && (recipient_emails.nil? || recipient_emails.empty?) && (recipient_access_groups.nil? || recipient_access_groups.empty?)
        logger.debug("There were no recipients found, sending back to new")
        if current_user.admin?
            flash[:info] = "That recipient list didn't work out."
          else
            flash[:info] = "You can only send messages to your friends"
          end
          #todo jme: need this?
          #@message = Message.new(params[:message])
          render :action => :new and return
      end

      @message_thread.from_id= current_user.id
      if @message_thread.title.nil? || @message_thread.title.blank?
        @message_thread.title= "(no subject)"
      end

      logger.debug("Starting new thread: #{@message_thread.title}")
      @message_thread.save!
      logger.debug("New thread id: #{@message_thread.id}")

    end # end if new thread
    
    logger.debug "Sending message from #{current_user.id} to #{recipient_emails.nil? ? '-' : recipient_ids.to_json}, #{recipient_emails.nil? ? '-' : recipient_emails.join(',')}"
    # Now we have all the ids, send the message to each one

    @body = @sent_message.body
    is_html = false

    if @shared_access
      @shared_item = @shared_access.item
      is_html = true
      @body = render_to_string :partial => "messages/shared_item", :locals => { :body => @sent_message.body }
    end
    
    @sent_message.thread_id = @message_thread.id
    @sent_message.from_id = current_user.id
    @sent_message.body = @body
    
    @sent_message.shared_access_id= @shared_access.id if @shared_access
    @sent_message.save!

    recipient_ids = [recipient_ids] if recipient_ids.class == String

    unless recipient_ids.nil?
      recipient_ids.uniq!
      recipient_ids.each do |recipient_id|
        logger.debug("Sending message #{@sent_message.id} to user id: #{recipient_id}")

        @message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
        @message.to_id= recipient_id
        @message.save!
      end
    end
    unless recipient_emails.nil?
      recipient_emails.uniq!
      recipient_emails.each do |email|
        logger.debug("Sending message  #{@sent_message.id} to email: #{email}")
        # don't clutter the messages table with these...
        #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
        #@message.to_email= email
        #@message.save!
        UserNotifier.deliver_generic(email, @message_thread.title, @body, :html => is_html, :from => current_user.email )
      end
    end
        
    # create a new array to keep all user ids that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_user_ids = Array.new
    all_sent_user_ids.concat(recipient_ids) unless recipient_ids.nil? || recipient_ids.empty?
    
    # create a new array to keep all email addresses that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_emails = Array.new
    all_sent_emails.concat(recipient_emails) unless recipient_emails.nil? || recipient_emails.empty?
    
    unless recipient_access_groups.nil?
      recipient_access_groups.each do |group|
        group_users = group.users()
        unless group_users.nil?
          group_users.uniq!
          group_users.each do |user|
            # don't deliver duplicate copies
            if all_sent_user_ids.include?(user.id)
              logger.debug("Skipping duplicate recipient user in access group: #{user.id}")
            else
              logger.debug("Sending message #{@sent_message.id} to access group user id: #{user.id}")
              
              # remember this user id so we don't send multiple copies
              all_sent_user_ids << user.id
              
              @message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
              @message.to_id= user.id
              @message.to_access_group_id= group.id
              @message.save!
            end
          end
        end
       
        # for each access group contact, send them the message via email -- translate SMS numbers to email
        group_contacts = group.contacts()
        unless group_contacts.nil?
          group_contacts.uniq!
         
          group_contacts.each do |contact|
            # don't deliver duplicate copies
            if all_sent_emails.include?(contact.destination)
              logger.debug("Skipping duplicate recipient email in access group: #{contact.destination}")
            else
              # remember this contact so we don't send multiple copies
              all_sent_emails << contact.destination
              
              email = contact.to_email_recipient
              logger.debug("Sending message  #{@sent_message.id} to access group recipient: #{contact.destination}")
        
              # don't clutter the messages table with these...
              #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
              #@message.to_email= email
              #@message.save!
              UserNotifier.deliver_generic(email, @message_thread.title, @body, :html => is_html, :from => current_user.email )
            end
          end
        end
      end
    end
   
    if new_thread
      # And finally, save the recipients in the thread
      logger.debug "Setting recipients for thread #{@message_thread.id}"

      #######
      # FLAG: to copy all the recipients out of the access group into the sent message,
      #   set "expand_access_group_contacts" to true
      expand_access_group_contacts = true
      if (expand_access_group_contacts)
        recipient_ids = all_sent_user_ids
        recipient_emails = all_sent_emails
     end
      #######
    
      unless recipient_ids.nil?
        to_ids,uses_alias = (is_alias ? Message.get_message_recipient_ids(params[:message_thread][:to_name],current_user,true) : [recipient_ids,false])
        @message_thread.to_ids_array= to_ids
      end
    
      @message_thread.to_emails_array= recipient_emails unless recipient_emails.nil?
    
      unless (recipient_access_groups.nil? || recipient_access_groups.empty?)
        group_ids = Array.new
        recipient_access_groups.each { |group| group_ids << group.id }
        logger.debug("Setting sent_message access groups to #{group_ids.join(',')}")
        @message_thread.to_access_group_ids_array= group_ids
      end
    
      @message_thread.save!

      logger.debug "The recipient list for the message thread was saved"
    end
    
    respond_to do |format|
      format.html { 
        flash[:notice] = "Your message was sent successfully."
        logger.debug "thread id #{@message_thread.id}"
        redirect_to :action => 'thread', :id => @message_thread.id and return
      }
      format.js
    end
#   rescue
#     logger.debug("In rescue block ZZZ: " + $! );
#     respond_to do |format|
#       format.html { render :action => "new" }
#       format.js
#     end
  end
  
  
  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id])
    if (! (current_user.admin? || current_user.id == @message.to_id))
      redirect_to user_path(current_user)
      return
    end
    @message.deleted = 1
    @message.save!
    
    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end
  
  def delete_multi
    c=0
    if params[:thread_id_check]
      params[:thread_id_check].each do |id|
        thread = MessageThread.find(id)
        thread.messages.for_user(current_user.id).each do |msg|
          next if msg.deleted
          msg.deleted = 1
          msg.save!
          c += 1
        end
      end
      flash[:info] = "#{c} message#{c>1?'s have':' has'} been deleted."
    else
      flash[:info] = "No messages selected for deletion"
    end

    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

  def mark_unread_multi
    c=0
    if params[:thread_id_check]
      params[:thread_id_check].each do |id|
        thread = MessageThread.find(id)
        thread.messages.for_user(current_user.id).each do |msg|
          next if msg.read==0
          message.read=0;
          message.save!
          c+=1
        end
      end
      flash[:info] = "#{c} conversation#{c>1?'s have':' has'} been marked unread."
    else
      flash[:info] = "No messages selected to mark unread"
    end

    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

  def mark_unread
    @message = Message.find(params[:id])
    if (! (current_user.admin? || current_user.id == @message.to_id))
      redirect_to user_path(current_user)
      return
    end
    @message.read=0
    @message.save!
    
    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

  def show
    @message = Message.find(params[:id])
    if (! (current_user.admin? || current_user.id == @message.to_id || current_user.id == @message.from_id) )
      redirect_to user_path(current_user)
      return
    end

    # Sir, gentlemen do not read other people's mail.
    # My good man, they do, but they don't mark it as 'read' when they do.
    if @message.unread? && current_user.id == @message.to_id
      @message.read= true
      @message.save!
    end
    
    respond_to do |format|
      format.html # => show.html.haml
      format.js # => show.rjs 
    end
  end

  # Auto complete for addressing message to people in your 
  # friends list by name
  def auto_complete_for_friend_full_name
    search_name = '%' + params[:message_thread][:to_name] + '%'
    if current_user.admin?
      @users = User.find(:all, :conditions => ["(LOWER(firstname) like ? or LOWER(lastname) like ?) and enabled = ?",search_name,search_name,true], :order => "lastname asc, firstname asc", :limit => 10)
    else
#      @friend_ids = Friendship.find(:all, :conditions => ['user_id = ? and friendship_status_id = ?',current_user.id,FriendshipStatus[:accepted].id]).collect(&:friend_id)
#      if @friend_ids.nil? || @friend_ids.size == 0
#        render :inline => '' and return
#      end

      @users = User.find(:all,
        :conditions => [
          "id in (?) and (LOWER(firstname) like ? or LOWER(lastname) like ?) and enabled = ?",
          current_user.mail_target_ids(),
          search_name,
          search_name,
          true
        ], :order => "lastname asc, firstname asc", :limit => 10)
    end
    choices = "<%= content_tag(:ul, @users.map { |u| content_tag(:li, h(u.full_name)) }) %>"
    render :inline => choices
  end

end
