class MessagesController < BaseController
  
  protect_from_forgery :except => [:auto_complete_for_friend_full_name]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :create, :thread ])

 
  # GET /messages
  # GET /messages.xml
  def index
    @thread_summary = true
    @message_threads = MessageThread.paginate :page => params[:page], :per_page => 20, :joins => "inner join messages on messages.thread_id = message_threads.id", :conditions => ["messages.to_id = ?", current_user.id], :order => "messages.created_at DESC"
    #@msgs = Message.paginate :page => params[:page], :per_page => 20, :conditions => ["deleted = 0 AND to_id = ?", current_user.id], :group => "thread_id", :order => "created_at DESC"
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

  def new_text
    @sms = true
    new
  end

  # GET /messages/new
  def new    
    setup_new_message_session
    
    # allow external-only emails to be sent for shared items
    shared_access_id = params[:shared_access_id] || (params[:sent_message] ? params[:sent_message][:shared_access_id] : nil)
    if shared_access_id
      logger.debug("sharing item: #{shared_access_id}")
      @shared_access = sharedaccess.find(shared_access_id.to_i)
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
      # tack the message on to an existing thread
      @message_thread = MessageThread.find(params[:re_thread].to_i)
    elsif params[:re]
      #start a new thread replying to an individual message
      @reply_to = SentMessage.find(params[:re].to_i)
      if @reply_to
        logger.debug "Replying to #{@reply_to.sender.full_name}"
        @message_thread = MessageThread.new(:from_id => current_user.id, :to_id => @reply_to.from_id, :title => "RE: #{@reply_to.message_thread.title}")
        @sent_message.thread_id = nil
        @sent_message.body = render_to_string :partial => "messages/reply_to", :locals => { :reply_to => @reply_to }
      end
    end
    
    if @message_thread.nil?
      @message_thread = MessageThread.new(params[:thread])
      @message_thread.title = params[:title] if params[:title]
      @message_thread.is_sms = true if @sms || params[:sms]
    
      if params[:to_id]
        begin
          @message_thread.to_id= User.find(params[:to_id].to_i).id
        rescue
          logger.debug("sked for a bad to_id #{params[:to_id]}")
        end
      end
      
      # list of available groups prepared by setup_new_message_session
      if params[:to_group] && session[:mail_to_coach_groups] 
        group_ids = Array.new
        group_params = Utilities::csv_split(params[:to_group])
        group_params.each do |param|
          matched = session[:mail_to_coach_groups].select {|group| group.id == param.to_i}
          if matched && !matched.empty?
            group_ids << matched.collect(&:id)
          end
        end
        unless group_ids.empty?
          @message_thread.to_access_group_ids_array= group_ids.flatten
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
    shared_access_id = params[:shared_access_id] || (params[:sent_message] ? params[:sent_message][:shared_access_id] : nil)
    if shared_access_id
      logger.debug("Sharing item: #{shared_access_id}")
      @shared_access = SharedAccess.find(shared_access_id.to_i)
    end

    @sent_message = SentMessage.new(params[:sent_message])

    new_thread = false
    thread_id = nil
    if params[:message_thread][:id] && !params[:message_thread][:id].empty?
      thread_id = params[:message_thread][:id].to_i
      @message_thread = MessageThread.find(thread_id)
    end

    recipient_roster_entries = Array.new
    recipient_ids = Array.new
    recipient_access_groups = Array.new
    recipient_emails = Array.new
    recipient_phones = Array.new
        
    # we may need to send a text or email notification
    text_notifications = Array.new
    email_notifications = Array.new
    
    if @message_thread && @message_thread.id
      new_thread = false
      
      # pull out user ids
      recipient_ids << @message_thread.to_ids_array
            
      recipient_emails << @message_thread.to_emails_array
      
      recipient_phones << @message_thread.to_phones_array
      
      # get groups
      if @message_thread.to_access_group_ids_array
        recipient_access_groups = AccessGroup.find(@message_thread.to_access_group_ids_array)
      end

      # get roster entries
      if @message_thread.to_roster_entry_ids_array
        recipient_roster_entries << RosterEntry.find(@message_thread.to_roster_entry_ids_array)
      end
            
      # add the original sender
      unless @message_thread.from_id == current_user.id
        # remove this "from_user" from the list of recipients
        recipient_ids = recipient_ids.delete_if {|id| id == current_user.id} unless recipient_ids.empty?
        recipient_roster_entries = recipient_roster_entries.delete_if {|roster| roster.user_id == current_user.id } unless recipient_roster_entries.empty?
        
        # add the original thread sender to the start of the list
        recipient_ids << @message_thread.from_id 
      end
      
    else
      new_thread = true
      @message_thread = MessageThread.new(params[:message_thread])
      
      if params[:message_thread][:to]
        entry_csv = params[:message_thread][:to]
        logger.debug ("Parsing TO: #{entry_csv}")
    
        recipient_errors = Array.new
        
        Utilities::csv_split(entry_csv).each do |entry|
          entry.strip!
          next if entry.length == 0
          
          # is it a group name
          if current_user.admin?
            access_group = AccessGroup.find(:first, :conditions => {:name => entry, :enabled => true})
          elsif session[:mail_to_coach_groups]
            access_group = session[:mail_to_coach_groups].select{ |group| group.name = entry }.shift
          end          
          if access_group
            logger.debug "Adding valid group '#{entry}'"
            recipient_access_groups << access_group
            next
          end

          # is it a roster entry
          if session[:mail_to_coach_groups]
            session[:mail_to_coach_groups].each do |group|
              roster_entry = group.roster().select{ |roster| roster.fullname = entry }.shift
              next if roster_entry
            end
            # found a roster entry... now what??
            if roster_entry
              recipient_roster_entries << roster_entry
            end
          end

          # is it an email address?
          emails = MessageThread.get_message_emails(entry)
          unless emails.nil? || emails.empty?
            logger.debug "Adding valid email address '#{entry}'"
            recipient_emails << emails
            recipient_emails.flatten!
            next
          end
          
          # is it a phone number
          phones = MessageThread.get_message_phones(entry)
          unless phones.nil? || phones.empty?
            logger.debug "Adding valid phone number '#{entry}'"
            recipient_phones << phones
            recipient_phones.flatten!
            next
          end
          
          # is it a gs user
          fn,ln = entry.split(' ')
          user = User.find(:first,
              :conditions => ['firstname = ? and lastname = ? and enabled = ?',fn,ln,true])
          if user
            recipient_ids << user.id
          end
          
          logger.error "Invalid recipient entry: #{entry}"
          recipient_errors << entry
        end
        
        @message_thread.to_roster_entry_ids= recipient_roster_entries.collect(&:id) unless recipient_roster_entries.empty?
        @message_thread.to_ids_array= recipient_ids unless recipient_ids.empty?
        @message_thread.to_emails_array= recipient_emails unless recipient_emails.empty?
        @message_thread.to_phones_array= recipient_phones unless recipient_phones.empty?
        @message_thread.to_access_group_ids_array= recipient_access_groups.collect(&:id) unless recipient_access_groups.empty?
        
        unless recipient_errors.empty?
          flash[:error] = "Invalid recipient entr#{recipient_errors.size > 1 ? 'ies' : 'y'}: #{recipient_errors.join(', ')}"
          render :action => :new and return
        end
      end
  
      # shortcut recipients for one-click-email links
      if params[:to_id]
        recipient_ids << params[:to_id].to_i
      end
      if params[:message_thread][:to_id]
        recipient_ids << params[:message_thread][:to_id].to_i
      end

      #this is a publication message
      report_id = params[:report] ? params[:report][:id] : nil
      if (report_id)
        report = Report.find(report_id)
  
        @access_item = AccessItem.new params[:access_item]
        if @access_item.access_group_id
          @access_item.item = report
          result = @access_item.save
        end
  
        logger.debug("Publish report #{report_id} access group id: #{@access_item.access_group_id}")
  
        recipient_access_groups = [@access_item.access_group]
      end
  
      if (recipient_roster_entries.nil? || recipient_roster_entries.empty?) &&
         (recipient_ids.nil? || recipient_ids.empty?) && 
         (recipient_emails.nil? || recipient_emails.empty?) && 
         (recipient_phones.nil? || recipient_phones.empty?) && 
         (recipient_access_groups.nil? || recipient_access_groups.empty?)
        
        logger.debug("There were no recipients found, sending back to new")
        if current_user.admin? 
            flash[:info] = "That recipient list didn't work out."
          else
            flash[:info] = "You can only send messages to your friends"
          end
          render :action => :new and return
      end

      @message_thread.from_id= current_user.id
      if @message_thread.title.nil? || @message_thread.title.blank?
        if (@message_thread.is_sms? || params[:sms]) && @sent_message.body && !@sent_message.body.blank?
          # take subject from first line of message
          @text_body = make_text_body(@sent_message.body)
          @text_body.each_line do |line|
            @message_thread.title = Utilities::truncate_words(line,10)
            break;
          end
        else
          @message_thread.title= "(no subject)"
        end
      end

      logger.debug("Starting new thread: #{@message_thread.title}")
      @message_thread.save!
      logger.debug("New thread id: #{@message_thread.id}")

    end # end if new thread
    
    logger.debug "Sending message from #{current_user.id} to roster entries=>#{recipient_roster_entries.nil? ? '-' : recipient_roster_entries.join(',')}, user ids=>#{recipient_ids.nil? ? '-' : recipient_ids.to_json}, emails=>#{recipient_emails.nil? ? '-' : recipient_emails.join(',')}, phones=>#{recipient_phones.nil? ? '-' : recipient_phones.join(',')}, groups=>#{recipient_access_groups.nil? ? '-' : recipient_access_groups.join(',')}"
    # Now we have all the ids, send the message to each one

    @body = @sent_message.body
    is_html = !@message_thread.is_sms?

    if @shared_access
      @shared_item = @shared_access.item
      is_html = true
      @body = render_to_string :partial => "messages/shared_item", :locals => { :body => @sent_message.body }
    end

    # don't allow blank messages to be sent
    if @body.nil? || @body.strip == ''
      flash[:info] = 'Cannot send a blank message'
      if @message_thread && @message_thread.id
        redirect_to :action => 'thread', :id => @message_thread.id, :anchor => 'reply' and return
      else
        render :action => :new and return
      end
    end
    
    @sent_message.thread_id = @message_thread.id
    @sent_message.from_id = current_user.id
    @sent_message.body = @body
    
    @sent_message.shared_access_id= @shared_access.id if @shared_access
    @sent_message.save!

    recipient_ids = [recipient_ids] if recipient_ids.class == String

    # create a new array to keep all roster_entries that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_roster_entries = Array.new
    all_sent_roster_entries.concat(recipient_roster_entries) unless recipient_roster_entries.nil? || recipient_roster_entries.empty?

    # create a new array to keep all user ids that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_user_ids = Array.new
    all_sent_user_ids.concat(recipient_ids) unless recipient_ids.nil? || recipient_ids.empty?
    
    # create a new array to keep all email addresses that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_emails = Array.new
    all_sent_emails.concat(recipient_emails) unless recipient_emails.nil? || recipient_emails.empty?

    # create a new array to keep all phone numbers that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_phones = Array.new
            
    # collect all the unique users, emails and phone numbers to message
    unless recipient_access_groups.nil? || recipient_access_groups.empty?
      recipient_access_groups.each do |group|
        
        # first account for access_users
        group_users = group.users
        unless group_users.nil?
          group_users.uniq!
          group_users.each do |user|
            # don't deliver duplicate copies
            unless all_sent_user_ids.include?(user.id)
              logger.debug("Adding access user for group (#{group.id}), user id: #{user.id}")
              all_sent_user_ids << [user.id,group.id]
            end
          end
        end
       
        # for each access roster entry in the group, send them the message via email -- translate SMS numbers to email
        roster_entries = group.roster
        all_sent_roster_entries << roster_entries unless roster_entries.nil? || roster_entries.empty?
      end
    end

    # This is a shortcut, assuming if the user is a coach anywhere, then he is a coach for all
    # teams here. 
    # The more exact way to to do this is to check, for every roster entry below:
    #    current_user.can?(Permission::COACH,roster_entry.access_group.team_id)
    sender_is_coach = current_user.can?(Permission::COACH)

    unless all_sent_roster_entries.nil? || all_sent_roster_entries.empty?
      all_sent_roster_entries.each do |roster_entry|

        # Logic for registered user roster entry
        # - Always send to internal messaging distribution channel
        # - For text messages, send the entire message if...
        #    * if sender is the coach
        #    * if the user's preferences allow text messaging (notifications)
        # - For non-text messages
        #    - send email notifications based on user preferences
        #    - send text notifications if requested (sent_message.sms_notify) if...
        #       * if sender is the coach
        #       * if user's preferences allow text notifications        
        if roster_entry.user_id && roster_entry.user_id > 0
          # user referenced in a roster supercedes user in recipient list,
          # so remove it if its there 
          all_sent_user_ids.delete_if!{|id| id == roster_entry.user_id}
          
          user = User.find(roster_entry.user_id)
          logger.debug("Delivering message for group (#{group.id}) recipient user id: #{user.id} #{user.full_name}")
          send_message_to_user(@sent_message, user, roster_entry.access_group_id)
        
          # If this is a text message... send the text
          if @message_thread.is_sms?
            if roster_entry.phone && !roster_entry.phone.blank?
              if sender_is_coach || user.notify_message_sms
                logger.debug("Adding group (#{group.id}) recipient phone number: #{roster_entry.phone}")
                all_sent_phones << roster_entry.phone
              end
            end
          else   
            # For non-text messages, send allowable notifications

            # 1. Only send a text message notificaiton if the sms_notify checkbox was checked
            # 2-a. If the recipient's coach is sending the message, ignore the user's notification settings
            # 2-b. For all other senders, only text if the user allows text message notifications (user.notify_message_sms)
            if @sent_message.sms_notify? && (sender_is_coach || user.notify_message_sms)
              if (roster_entry.phone && !roster_entry.phone.blank?)
                logger.debug("Notifying user #{roster_entry.user_i} roster entry via phone #{roster_entry.phone}")
                text_notifications << roster_entry.phone
              end
            end
            
            #  Send an email notification if the user's notification settings permit (user.notify_message_email)
            if user.notify_message_email
              if (roster_entry.email && !roster_entry.email.blank?)
                logger.debug("Notifying user #{roster_entry.user_i} roster entry via email: #{roster_entry.email}")
                email_notifications << roster_entry.email
              end
            end
          end
       else
          # Non-registered user roster entries
          if @message_thread.is_sms? && sender_is_coach && roster_entry.phone && !roster_entry.phone.blank?
            logger.debug("Adding group (#{group.id}) recipient phone #{roster_entry.phone}")
            all_sent_phones << roster_entry.phone
          else
            if roster_entry.email && !roster_entry.email.blank?
              logger.debug("Adding group (#{group.id}) recipient email: #{roster_entry.email}")
              all_sent_emails << roster_entry.email
            end
            
            if @sent_message.sms_notify && sender_is_coach
              logger.debug("Notifying non-user roster entry via phone: #{roster_entry.phone}")
              text_notifications << roster_entry.phone
            end
          end
        end
      end
    end
    
    unless all_sent_user_ids.nil? || all_sent_user_ids.empty?
      all_sent_user_ids.uniq!
      all_sent_user_ids.each do |user_id|
        user = User.find(user_id)
        logger.debug("Delivering message to user id: #{user.id} #{user.full_name}")
        send_message_to_user(@sent_message, user)
      end
    end
    unless all_sent_emails.nil? || all_sent_emails.empty?
      all_sent_emails.uniq!
      all_sent_emails.each do |email|
        logger.debug("Sending message  #{@sent_message.id} to email: #{email}")
        # don't clutter the messages table with these...
        #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
        #@message.to_email= email
        #@message.save!
        begin
          UserNotifier.deliver_generic(email, @message_thread.title, @body, :html => is_html, :from => current_user.email )
        rescue Exception => e
          logger.error "Error sending email to #{email}: #{e.message}"
          flash[:error] = "Unable to send email to #{email}"
        end          
      end
    end
    unless all_sent_phones.nil? || all_sent_phones.empty?
      if @text_body.nil?
        @text_body = make_text_body(@body)
      end

      all_sent_phones.uniq!
      all_sent_phones.each do |sms|
        # translate SMS numbers to email
        email = UserNotifier::sms_to_email(sms)
        logger.debug("Sending message  #{@sent_message.id} to phone number: #{sms}")
  
        # don't clutter the messages table with these...
        #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
        #@message.to_email= email
        #@message.save!
        begin
          # subject = '' for text messages
          UserNotifier.deliver_generic(email, '', @text_body, :html => false, :from => current_user.email )
        rescue Exception => e
          logger.error "Error sending email for sms #{sms} to #{email}: #{e.message}"
          flash[:error] = "Unable to send message to #{Utilities::readable_phone(sms)}"
        end
      end
    end
 
    if new_thread
      # And finally, save the recipients in the thread
      logger.debug "Setting recipients for thread #{@message_thread.id}"
      
      @message_thread.to_roster_entry_ids_array= recipient_roster_entries.collect(&:id).flatten unless recipient_roster_entries.empty?
      @message_thread.to_ids_array= recipient_ids.flatten unless recipient_ids.nil? || recipient_ids.empty?
      @message_thread.to_access_group_ids_array= recipient_access_groups.collect(&:id).flatten unless recipient_access_groups.empty?
      @message_thread.to_emails_array= recipient_emails.flatten unless recipient_emails.empty?
      @message_thread.to_phones_array= recipient_phones.flatten unless recipient_phones.empty?
    
      @message_thread.save!

      logger.debug "The recipient list for the message thread was saved"
    end

    # clean up session objects
    session[:mail_to_user_ids] = nil
    session[:mail_to_coach_groups] = nil
    
    # send notifications, if necessary
    unless email_notifications.empty? && text_notifications.empty?
      send_message_notifications(@sent_message, email_notifications, text_notifications)
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
    max_suggestions = 10

    if params[:message_thread][:to]
      suggestion_count = 0

      search_name = params[:message_thread][:to].strip.downcase
      search_name_sql = search_name + '%'
      
      # search using bidirectional wildcard if they've typed more than a couple letters
      search_name_sql = '%' + search_name_sql if search_name.length > 3
      
      logger.debug "Auto complete for '#{search_name}'"

      # Expect cached friend ids on the session (from 'new' action)
      friend_ids = session[:mail_to_user_ids]
      
      # Expect cached coach access groups on the session (from 'new' action)
      coach_access_groups = session[:mail_to_coach_groups]
      
      # the order by "(id in (<friend_list>)) desc" clause puts friends at the top of the list
      @users = User.find(:all, 
          :conditions => ["(LOWER(firstname) like ? or LOWER(lastname) like ?) and enabled = ?",search_name_sql,search_name_sql,true], 
          :order => "(id in (#{friend_ids && !friend_ids.empty? ? friend_ids.join(',') : '0'})) desc, lower(lastname) asc, lower(firstname) asc", 
          :limit => 5)

      if current_user.admin?
        @groups = AccessGroup.find(:all, 
            :conditions => ["lower(name) like ? and enabled=?",search_name_sql,true], 
            :order => "lower(name)", :limit => 5)
      else
        if coach_access_groups && coach_access_groups.empty?
          @groups = AccessGroup.find(:all, 
              :conditions => ["lower(name) like ? and id in (?) and enabled=?",
                              search_name_sql,coach_access_groups,true], 
              :order => "lower(name)", :limit => 5)
          
          @roster_entries = RosterEntry.find(:all, 
              :conditions => ["access_group_id in (?) and (lower(firstname) like ? or lower(lastname) like ?)", 
                              coach_access_groups, search_name_sql,search_name_sql],
              :order => "lower(firstname), lower(lastname)", :limit => 5)
          
          # pull users out of roster entries, leaving only non-registered addresses
          if @roster_entries
            # put roster entries first in the @users list
            @users = @roster_entries.collect{|r| r.user}.compact.concat(@users).uniq
            
            # remove the @roster entries that have user_ids
            @roster_entries = @roster_entries.select {|r| r.user_id.nil?}
          end
        end
      end
      
      # update the suggestion count
      suggestion_count += @groups.length unless @groups.nil?
      suggestion_count += @users.length unless @users.nil?
      suggestion_count += @roster_entries.length unless @roster_entries.nil?
      
      if suggestion_count < max_suggestions 
        if search_name.match(/\d/)
          stripped = search_name.gsub(/[^\w]/,'')
          if stripped.match(/^\d+$/)
            # search for phones using %search% wildcard strategy since there may be multiple
            # comma (or backslash) separated entries in one field
            phone_search_sql = '%' + stripped + '%'
            threads = MessageThread.find(:all, :select => "distinct to_phones", 
                :conditions => ["from_id=? and to_phones like ?",current_user.id,phone_search_sql], 
                :limit => 5)
            if threads && !threads.empty?
              @phones = Array.new
              threads.each do |thread|
                # extract the individual phone numbers that match the search string
                p = thread.to_phones_array.select {|phone| phone.include?(stripped)}
                if p && !p.empty?
                  @phones << p
                end
              end
              @phones = @phones.flatten.uniq
              @phones = nil if @phones.empty?

              # update the suggestion count
              suggestion_count += @phones.length unless @phones.nil?
            end
          end
        end
        
        if suggestion_count < max_suggestions
          # search for emails using %search% wildcard strategy since there may be multiple
          # comma (or backslash) separated entries in one field
          search_email_sql= '%' + search_name + '%'
                
          threads = MessageThread.find(:all, :select => "distinct to_emails", :conditions => ["from_id=? and lower(to_emails) like ?",current_user.id,search_email_sql], :limit => 5)
          if threads && !threads.empty?
            @emails = Array.new
            threads.each do |thread|
              # extract the individual phone numbers that match the search string
              e = thread.to_emails_array.select {|email| email.downcase.include?(search_name)}
              if e && !e.empty?
                @emails << e
              end
            end
            @emails = @emails.flatten.uniq
            @emails = nil if @emails.empty?

            # update the suggestion count
            suggestion_count += @emails.length unless @emails.nil?
          end
        end

        logger.debug("Found #{suggestion_count} suggestion(s) for #{search_name}")
      end
      
      #choices = "<%= content_tag(:ul, @users.map { |u| content_tag(:li, h(u.full_name)) }) %>"
      #render :inline => choices
      logger.debug(render_to_string :partial => "messages/auto_complete_for_users")
      render :partial => "messages/auto_complete_for_users"
    end
  end

  private
  
  def make_text_body(body)    
    # strip tags for text message recipients
    text_body = ActionController::Base.helpers.strip_tags(body)
    
    # strip out cr-lf
    text_body.gsub!(/[\r\n]/m, ' ') 
    # strip out non alpha-num-punct chars
    text_body.gsub!(/[^A-Za-z0-9!-~]/, ' ')
    # normalize spaces
    text_body.squeeze!
    # remove leading and trailing whitespace
    text_body.strip!
    
    if text_body.length > 160
      read_more_link = " View full message @ globalsports.net"
      maxlength = 160-(read_more_link.length)
      text_body = text_body.slice(0,maxlength-3).concat('...')
    end
   
    return text_body
  end

  def setup_new_message_session    
    # save some time keeping friend ids on the session
    friend_ids = current_user.mail_target_ids
    session[:mail_to_user_ids] = friend_ids unless friend_ids.nil?

    # cache coach access groups on the session
    team_sports = current_user.scopes_for(Permission::COACH)
    if team_sports && !team_sports.empty?
      team_ids = team_sports.collect(&:team_id).compact
      coach_access_groups = AccessGroup.find(:all, :conditions => ["team_id in (?) and enabled=?",team_ids,true])
      session[:mail_to_coach_groups] = coach_access_groups unless coach_access_groups.nil?
    end
  end
  
  def self.send_message_to_user(sent_message, user, access_group_id=nil)
    if sent_message && user
      logger.debug("Delivering message #{sent_message.id} to user: #{user.id} #{user.full_name}")
  
      message = Message.new(:sent_message_id => sent_message.id, :thread_id => sent_message.thread_id)
      message.to_id= user.id
      message.to_access_group_id= access_group_id unless access_group_id.nil?
      message.save!
    end
  end  
  
  def self.send_message_notifications(sent_message, emails, phone_numbers)
    if sent_message
      if emails
        emails.each do |email|
          logger.debug("Sending message notification to #{email}")
          UserNotifier.deliver_new_message(sent_message, email)
        end
      end
      if phone_numbers
        phone_numbers.each do |phone|
          logger.debug("Sending message notification to #{phone}")
          UserNotifier.deliver_new_message_sms(sent_message, phone)
        end
      end
    end
  end

  
end
