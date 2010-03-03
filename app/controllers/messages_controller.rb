class MessagesController < BaseController
  
  protect_from_forgery :except => [:auto_complete_for_friend_full_name, :pop_group_choices]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :create, :thread ])

 
  # GET /messages
  # GET /messages.xml
  def index
    @thread_summary = true
    @message_threads = MessageThread.paginate :page => params[:page], :per_page => 20, :joins => "inner join messages on messages.thread_id = message_threads.id", :conditions => ["messages.to_id = ?", current_user.id], :order => "messages.created_at DESC", :group => 'message_threads.id'
    #@message_threads = MessageThread.paginate :page => params[:page], :per_page => 20, :joins => "inner join messages on messages.thread_id = message_threads.id", :conditions => ["messages.to_id = ?", current_user.id], :order => "messages.created_at DESC"
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
      logger.debug("Sharing item: #{shared_access_id}")
      @shared_access = SharedAccess.find(shared_access_id.to_i)
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
      if params[:to_group] && (session[:mail_to_coach_group_ids] || session[:mail_to_member_group_ids]) 
        group_ids = Array.new
        group_params = Utilities::csv_split(params[:to_group])
        group_params.each do |param|
          if session[:mail_to_coach_group_ids]
            matched = session[:mail_to_coach_group_ids].select {|group_id| group_id == param.to_i}
            if matched && !matched.empty?
              group_ids << matched
              next
            end
          end
          if session[:mail_to_member_group_ids]
            matched = session[:mail_to_member_group_ids].select {|group_id| group_id == param.to_i}
            if matched && !matched.empty?
              group_ids << matched
              next
            end
          end
        end
        unless group_ids.empty?
          @message_thread.to_access_group_ids_array= group_ids.flatten.compact.uniq
        end
      end

      # list of available groups prepared by setup_new_message_session
      if params[:to_roster] && session[:mail_to_coach_group_ids] 
        roster_ids = Array.new
        roster_params = Utilities::csv_split(params[:to_roster])
        roster_params.each do |param|
          # look up the roster entry record
          roster_entry = RosterEntry.find(param.to_i)
          # make sure this roster entry is associated with one of this coach's groups
          if session[:mail_to_coach_group_ids].include?(roster_entry.access_group_id)
            roster_ids << roster_entry.id
            next
          end
        end
        unless roster_ids.empty?
          @message_thread.to_roster_entry_ids_array= roster_ids.flatten.compact.uniq
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
      recipient_ids.flatten!
            
      recipient_emails << @message_thread.to_emails_array
      recipient_emails.flatten!
      
      recipient_phones << @message_thread.to_phones_array
      recipient_phones.flatten!
      
      # get groups
      if @message_thread.to_access_group_ids_array
        recipient_access_groups = AccessGroup.find(@message_thread.to_access_group_ids_array)
        recipient_access_groups.flatten!
      end

      # get roster entries
      if @message_thread.to_roster_entry_ids_array
        recipient_roster_entries << RosterEntry.find(@message_thread.to_roster_entry_ids_array)
        recipient_roster_entries.flatten!
      end
            
      # add the original sender
      unless @message_thread.from_id == current_user.id
        # remove this "from_user" from the list of recipients
        recipient_ids = recipient_ids.reject {|id| id == current_user.id} unless recipient_ids.empty?
        recipient_roster_entries = recipient_roster_entries.reject {|roster| roster.user_id == current_user.id } unless recipient_roster_entries.empty?
        
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
          else
            if session[:mail_to_coach_group_ids]
              access_group = AccessGroup.find(:first, :conditions => {:id => session[:mail_to_coach_group_ids], :name => entry})
            end
            if access_group.nil? && session[:mail_to_member_group_ids]
              access_group = AccessGroup.find(:first, :conditions => {:id => session[:mail_to_member_group_ids], :name => entry})
            end
          end          
          if access_group
            logger.debug "Adding valid group '#{entry}'"
            recipient_access_groups << access_group
            next
          end

          #used by roster lookup and user lookup
          fn,ln = entry.split(' ')

          # is it a roster entry
          if session[:mail_to_coach_group_ids]
            roster_entry = RosterEntry.find(:first, :conditions => {:access_group_id => session[:mail_to_coach_group_ids], :firstname => fn, :lastname => ln})
            if roster_entry
              logger.debug "Adding roster entry #{roster_entry.id}: #{entry}"
              recipient_roster_entries << roster_entry
              next
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
          
          # is it a gs user?
          # Seems like find(:first) would be better, but if there are multiple users with the same name,
          # how do we know they meant to send it to the first, and not the second. Ugly problem....
          users = User.find(:all, :conditions => {:firstname => fn, :lastname => ln, :enabled => true})
          unless users.nil? || users.empty?
            recipient_ids << users.collect(&:id)
            recipient_ids.flatten!
            next
          end
          
          logger.error "Invalid recipient entry: #{entry}"
          recipient_errors << entry
        end
        
        @message_thread.to_roster_entry_ids= recipient_roster_entries.collect(&:id).uniq unless recipient_roster_entries.empty?
        @message_thread.to_ids_array= recipient_ids.uniq unless recipient_ids.empty?
        @message_thread.to_emails_array= recipient_emails.uniq unless recipient_emails.empty?
        @message_thread.to_phones_array= recipient_phones.uniq unless recipient_phones.empty?
        @message_thread.to_access_group_ids_array= recipient_access_groups.collect(&:id).uniq unless recipient_access_groups.empty?
        
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
    all_sent_roster_entries << recipient_roster_entries unless recipient_roster_entries.nil? || recipient_roster_entries.empty?

    # create a new array to keep all user ids that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_user_ids = Array.new
    all_sent_user_ids << recipient_ids unless recipient_ids.nil? || recipient_ids.empty?

    # create a new array to keep all email addresses that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_emails = Array.new
    all_sent_emails << recipient_emails unless recipient_emails.nil? || recipient_emails.empty?

    # create a new array to keep all phone numbers that this message
    # was sent to, so that we can avoid sending duplicate messages
    all_sent_phones = Array.new
    all_sent_phones << recipient_phones unless recipient_phones.nil? || recipient_phones.empty?

    logger.debug "Sending message from #{current_user.id} to roster entries=>#{all_sent_roster_entries.collect(&:id).to_json}, user ids=>#{all_sent_user_ids.to_json}, emails=>#{all_sent_emails.to_json}, phones=>#{all_sent_phones.to_json}, groups=>#{recipient_access_groups.nil? ? '[]' : recipient_access_groups.collect(&:id).to_json}"
    # Now we have all the ids, send the message to each one

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
              all_sent_user_ids << user.id
            end
          end
        end
       
        # for each access roster entry in the group, send them the message via email -- translate SMS numbers to email
        roster_entries = group.roster
        all_sent_roster_entries << roster_entries unless roster_entries.nil? || roster_entries.empty?
      end
    end

    # Clean up all of the arrays... remove nulls, flatten nested arrays, and remove dupes 
    all_sent_roster_entries = all_sent_roster_entries.flatten.compact.uniq unless all_sent_roster_entries.empty?

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
          all_sent_user_ids = all_sent_user_ids.reject{|id| id == roster_entry.user_id}
          
          user = User.find(roster_entry.user_id)
          logger.debug("Delivering message roster entry (#{roster_entry.id} in group #{roster_entry.access_group_id}) recipient user id: #{user.id} #{user.full_name}")
          send_message_to_user(@sent_message, user)#, roster_entry.access_group_id)
        
          # If this is a text message... send the text
          if @message_thread.is_sms?
            if roster_entry.phone && !roster_entry.phone.blank?
              if sender_is_coach || user.notify_message_sms
                logger.debug("Adding group (#{roster_entry.access_group_id}) recipient phone number: #{roster_entry.phone}")
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
                logger.debug("Notifying user #{roster_entry.user_id} roster entry (#{roster_entry.id} in group #{roster_entry.access_group_id}) via phone #{roster_entry.phone}")
                text_notifications << roster_entry.phone
              end
            end
            
            #  Send an email notification if the user's notification settings permit (user.notify_message_email)
            if user.notify_message_email
              if (roster_entry.email && !roster_entry.email.blank?)
                logger.debug("Notifying user #{roster_entry.user_id} roster entry (#{roster_entry.id} in group #{roster_entry.access_group_id}) via email: #{roster_entry.email}")
                email_notifications << roster_entry.email
              end
            end
          end
       else
          # Non-registered user roster entries
          if @message_thread.is_sms? && sender_is_coach && roster_entry.phone && !roster_entry.phone.blank?
            logger.debug("Adding phone for roster (#{roster_entry.id} in group #{roster_entry.access_group_id}): #{roster_entry.phone}")
            all_sent_phones << roster_entry.phone
          else
            if roster_entry.email && !roster_entry.email.blank?
              logger.debug("Adding email for roster (#{roster_entry.id} in group #{roster_entry.access_group_id}): #{roster_entry.email}")
              all_sent_emails << roster_entry.email
            end
            
            if @sent_message.sms_notify && sender_is_coach
              logger.debug("Notifying non-user roster entry (#{roster_entry.id} in group #{roster_entry.access_group_id}) via phone: #{roster_entry.phone}")
              text_notifications << roster_entry.phone
            end
          end
        end
      end
    end

    # Clean up all of the arrays... remove nulls, flatten nested arrays, and remove dupes 
    #logger.debug("**DEBUG: Before uniq, all_sent_user_ids #{all_sent_user_ids.length}: #{all_sent_user_ids.to_json}")
    all_sent_user_ids = all_sent_user_ids.flatten.compact.uniq unless all_sent_user_ids.empty?
    #logger.debug("**DEBUG: After uniq, all_sent_user_ids #{all_sent_user_ids.length}: #{all_sent_user_ids.to_json}")
    
    #logger.debug("**DEBUG: Before uniq, all_sent_emails #{all_sent_emails.length}: #{all_sent_emails.to_json}")
    all_sent_emails = all_sent_emails.flatten.compact.uniq unless all_sent_emails.empty?
    #logger.debug("**DEBUG: After uniq, all_sent_emails #{all_sent_emails.length}: #{all_sent_emails.to_json}")
    
    #logger.debug("**DEBUG: Before uniq, all_sent_phones #{all_sent_phones.length}: #{all_sent_phones.to_json}")
    all_sent_phones = all_sent_phones.flatten.compact.uniq unless all_sent_phones.empty?
    #logger.debug("**DEBUG: After uniq, all_sent_phones #{all_sent_phones.length}: #{all_sent_phones.to_json}")
    
    unless all_sent_user_ids.empty?
      all_sent_user_ids.each do |user_id|
        user = User.find(user_id)
        logger.debug("Delivering message to user id: #{user.id} #{user.full_name}")
        send_message_to_user(@sent_message, user)
        
        sent_text_message = false
        # Send a text notification if the user's notificaiton settings permit (user.notify_message_sms
        # AND the sender has requested that text notifcations be sent
        if user.notify_message_sms && user.phone && !user.phone.blank?
          # send the whole text message if on the send_text screen
          if @message_thread.is_sms?
            logger.debug("Sending text to user #{user.id} via phone #{user.phone}")
            all_sent_phones << user.phone
            sent_text = true
          elsif @sent_message.sms_notify?
            logger.debug("Notifying user #{user.id} via phone #{user.phone}")
            text_notifications << user.phone
            logger.debug("**DEBUG: text_notifications #{text_notifications.join(',')}")
          end
        end
                
        #  Send an email notification if the user's notification settings permit (user.notify_message_email)
        unless sent_text_message
          if user.notify_message_email && user.email && !user.email.blank?
            logger.debug("Notifying user #{user.id} via email: #{user.email}")
            email_notifications << user.email
            logger.debug("**DEBUG: email_notifications: #{email_notifications.join(',')}")
          end
        end
      end
    end

    unless all_sent_emails.empty?
      all_sent_emails.each do |email|
        logger.debug("Sending message #{@sent_message.id} to email: '#{email}'")
        # don't clutter the messages table with these...
        #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
        #@message.to_email= email
        #@message.save!
        begin
          UserNotifier.deliver_generic(email, @message_thread.title, @body, :html => is_html, :from => current_user.email )
        rescue Exception => e
          logger.error "Error sending email to '#{email}': #{e.message}"
          flash[:error] = "Unable to send email to '#{email}'"
        end          
      end
    end
    
    unless all_sent_phones.empty?
      if @text_body.nil?
        @text_body = make_text_body(@body)
      end
      
      all_sent_phones.each do |sms|
        # translate SMS numbers to email
        email = UserNotifier::sms_to_email(sms)
        logger.debug("Sending message #{@sent_message.id} via email gateway to phone number: #{sms}")
  
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
      
      @message_thread.to_roster_entry_ids_array= recipient_roster_entries.collect(&:id).flatten.compact.uniq unless recipient_roster_entries.empty?
      @message_thread.to_ids_array= recipient_ids.flatten.compact.uniq unless recipient_ids.nil? || recipient_ids.empty?
      @message_thread.to_access_group_ids_array= recipient_access_groups.collect(&:id).flatten.compact.uniq unless recipient_access_groups.empty?
      @message_thread.to_emails_array= recipient_emails.flatten.compact.uniq unless recipient_emails.empty?
      @message_thread.to_phones_array= recipient_phones.flatten.compact.uniq unless recipient_phones.empty?
    
      @message_thread.save!

      logger.debug "The recipient list for the message thread was saved"
    end

    # clean up session objects
    session[:mail_to_user_ids] = nil
    session[:mail_to_coach_group_ids] = nil
    session[:mail_to_member_group_ids] = nil
    
    # send notifications, if necessary
    email_notifications.uniq! unless email_notifications.empty?
    text_notifications.uniq! unless text_notifications.empty?
    send_message_notifications(@sent_message, email_notifications, text_notifications)
    
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
          msg.read=0;
          msg.save!
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
      coach_access_group_ids = session[:mail_to_coach_group_ids]
      
      # Expect cached groups that user is a member of on the session (from 'new' action'
      member_access_group_ids = session[:mail_to_member_group_ids]
      
      # only look up users by first/last name if there is no number or @ in the entered value
      unless search_name.match(/[\d@]/)
        names = search_name.split(' ')
        if names.length > 1
          fn = names[0] + '%'
          ln = names[1] + '%'
        else
          fn = search_name + '%'
          ln = fn
        end

        @friends = User.find(:all, 
            :conditions => ["id in (?) and (lower(firstname) like ? or lower(lastname) like ?) and enabled = ?",friend_ids,fn,ln,true], 
            :order => "lower(firstname) asc, lower(lastname) asc", 
            :limit => 5) unless friend_ids.nil? || friend_ids.empty?

        # update the suggestion count
        suggestion_count += @friends.length unless @friends.nil?

        if suggestion_count < max_suggestions
          logger.debug ("Found #{suggestion_count} friends, looking for roster entries next")
  
          if coach_access_group_ids && !coach_access_group_ids.empty?
            @roster_entries = RosterEntry.find(:all, 
                :conditions => ["access_group_id in (?) and (lower(firstname) like ? or lower(lastname) like ?)", 
                                coach_access_group_ids, fn, ln],
                :order => "lower(firstname) asc, lower(lastname) asc", :limit => 5)
            
            # pull users out of roster entries, leaving only non-registered addresses
            if @roster_entries
              # put roster entries first in the @users list
              roster_users = @roster_entries.collect{|r| r.user}.compact
              if roster_users && !roster_users.empty?
                if @friends
                  @friends = @friends | roster_users
                else
                  @friends = roster_users
                end
                
                # remove the @roster entries that have user_ids
                @roster_entries = @roster_entries.select {|r| r.user_id.nil?}
              end
            end
          end
          
          # update the suggestion count
          suggestion_count = 0
          suggestion_count += @friends.length unless @friends.nil?
          suggestion_count += @roster_entries.length unless @roster_entries.nil?
        
          if suggestion_count < max_suggestions
            logger.debug ("Found #{suggestion_count} friends && roster entries, searching all users")

            @users = User.find(:all, 
                :conditions => ["(lower(firstname) like ? or lower(lastname) like ?) and enabled = ?",fn,ln,true], 
                :order => "lower(firstname) asc, lower(lastname) asc", 
                :limit => 5)
            if @users
              if @friends
                @users = @users - @friends
              end
              suggestion_count += @users.length if @users
            end
          end
        end
      end

      if current_user.admin?
        @groups = AccessGroup.find(:all, 
            :conditions => ["lower(name) like ? and enabled=?",search_name_sql,true], 
            :order => "lower(name)", :limit => 5)
      else
        search_group_ids = Array.new
        search_group_ids << coach_access_group_ids if coach_access_group_ids 
        search_group_ids << member_access_group_ids if member_access_group_ids
        unless search_group_ids.empty?
          @groups = AccessGroup.find(:all, 
              :conditions => ["lower(name) like ? and id in (?) and enabled=?",
                              search_name_sql,search_group_ids.flatten.uniq,true], 
              :order => "lower(name)", :limit => 5)
        end
      end
      
      # update the suggestion count
      suggestion_count += @groups.length unless @groups.nil?
      
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
      render :partial => "messages/auto_complete_for_users"
    end
  end

  def pop_group_choices
    group_ids = Array.new
    group_ids << session[:mail_to_coach_group_ids] if session[:mail_to_coach_group_ids] 
    group_ids << session[:mail_to_member_group_ids] if session[:mail_to_member_group_ids] 
    @groups = AccessGroup.find(group_ids.flatten.uniq, :order => :name) unless group_ids.empty?
    
    render :update do |page|
      target = "dialog"
      page.replace_html target, :partial => 'pop_group_choices'
    end
  end

  private
  
  def make_text_body(body)    
    # strip tags for text message recipients
    text_body = ActionController::Base.helpers.strip_tags(body)
    
    # strip out non alpha-num-punct chars
    # normalize spaces
    text_body = text_body.gsub(/[^A-Za-z0-9!-~\n\r]/, ' ').gsub(/&nbsp;/, ' ').squeeze(' ')

    # strip out cr-lf
    # normalize lines
    text_body = text_body.gsub(/\s*[\r\n]\s*/m, "\n").squeeze("\n") 

    # remove leading and trailing whitespace
    text_body.strip!
    
    if text_body.length > 160
      read_more_link = "...\nLogin to globalsports.net to read more"
      maxlength = 160-(read_more_link.length)
      text_body = text_body.slice(0,maxlength)
      text_body += read_more_link
    end
   
    return text_body
  end

  def setup_new_message_session    
    # save some time keeping friend ids on the session
    friend_ids = current_user.mail_target_ids
    session[:mail_to_user_ids] = friend_ids unless friend_ids.nil? || friend_ids.empty?

    # cache coach access groups on the session
    #  - coaches can send to individual roster entries
    team_sports = current_user.scopes_for(Permission::COACH)
    if team_sports && !team_sports.empty?
      team_ids = team_sports.collect(&:team_id).compact
      coach_access_groups = AccessGroup.find(:all, :conditions => ["team_id in (?) and enabled=?",team_ids,true])
      session[:mail_to_coach_group_ids] = coach_access_groups.collect(&:id) unless coach_access_groups.nil? || coach_access_groups.empty?
    end
    
    # cache member access groups on the session
    #   - members can send to entire group, but not individual roster entries
    member_groups = AccessGroup.for_user(current_user)
    if member_groups && !member_groups.empty?
      ids = member_groups.collect(&:id)
      session[:mail_to_member_group_ids] = ids unless ids.empty?
    end
  end
  
  def send_message_to_user(sent_message, user, access_group_id=nil)
    if sent_message && user
      logger.debug("Delivering message #{sent_message.id} to user: #{user.id} #{user.full_name}")
  
      message = Message.new(:sent_message_id => sent_message.id, :thread_id => sent_message.thread_id)
      message.to_id= user.id
      message.to_access_group_id= access_group_id unless access_group_id.nil?
      message.save!
    end
  end  
  
  def send_message_notifications(sent_message, emails, phone_numbers)
    if sent_message
      if emails && !emails.empty?
        emails.each do |email|
          unless email.blank?
            logger.debug("Sending message notification to #{email}")
            UserNotifier.deliver_new_message(sent_message, email)
          end
        end
      end
      if phone_numbers && !phone_numbers.empty?
        phone_numbers.each do |phone|
          unless phone.blank?
            logger.debug("Sending message notification to #{phone}")
            UserNotifier.deliver_new_message_sms(sent_message, phone)
          end
        end
      end
    end
  end

  
end
