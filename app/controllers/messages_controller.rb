class MessagesController < BaseController
  
  protect_from_forgery :except => [:auto_complete_for_friend_full_name]
  uses_tiny_mce(:options => AppConfig.gsdefault_mce_options, :only => [:new, :create ])

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
      # tack the message on to an existing thread
      @message_thread = MessageThread.find(params[:re_thread].to_i)
    elsif params[:re]
      #start a new thread replying to an individual message
      @reply_to = SentMessage.find(params[:re].to_i)
      if @reply_to
        @message_thread = MessageThread.new(:from_id => current_user.id, :to_id => @reply_to.from_id, :title => "RE: #{@reply_to.message_thread.title}")
        @sent_message.body = render_to_string :partial => "messages/reply_to", :locals => { :reply_to => @reply_to }
      end
    end
    
    if @message_thread.nil?
      @message_thread = MessageThread.new(params[:thread])
      @message_thread.title = params[:title] if params[:title]
    
      if params[:to_id]
        begin
          @message_thread.to_id= User.find(params[:to_id].to_i).id
        rescue
          logger.debug("sked for a bad to_id #{params[:to_id]}")
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

  def new_text
    @sent_message = SentMessage.new(params[:sent_message]);
    @message_thread = MessageThread.new
    @sms = true
    render :action => :new, :locals => { :sms => @sms } 
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
    use_alias = false
    thread_id = nil
    if params[:message_thread][:id] && !params[:message_thread][:id].empty?
      thread_id = params[:message_thread][:id].to_i
      @message_thread = MessageThread.find(thread_id)
    end

    recipient_ids = Array.new
    recipient_emails = Array.new
    recipient_phones = Array.new
    recipient_access_groups = Array.new
    
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
      
      recipient_phones = @message_thread.to_phones_array
      
      if @message_thread.to_access_group_ids_array
        recipient_access_groups = AccessGroup.find(@message_thread.to_access_group_ids_array)
      end
      
    else
      new_thread = true
      @message_thread = MessageThread.new(params[:message_thread])
      
      if params[:message_thread][:to]
        entry_csv = params[:message_thread][:to]
        logger.debug ("Parsing TO: #{entry_csv}")
    
        recipient_errors = Array.new
        
        entry_csv.split(',').each do |entry|
          entry.strip!
          
          # is it an email address?
          emails = MessageThread.get_message_emails(entry)
          unless emails.nil? || emails.empty?
            logger.debug "Adding valid email address #{entry}"
            recipient_emails << emails
            recipient_emails.flatten!
            next
          end
          
          # is it a phone number
          phones = MessageThread.get_message_phones(entry)
          unless phones.nil? || phones.empty?
            logger.debug "Adding valid phone number #{entry}"
            recipient_phones << phones
            recipient_phones.flatten!
            next
          end
          
          if current_user.team_staff?
            access_group = AccessGroup.find(:first, conditions => {:team_id => current_user.team_id, :name => entry, :enabled => true})
            if access_group
              recipient_access_groups << access_group
              next
            end
          end
          
          begin
            ids,is_alias =
              MessageThread.get_message_recipient_ids(entry, current_user)
            unless ids.nil? || ids.empty?
              recipient_ids << ids
              use_alias ||= is_alias
              recipient_ids.flatten!
              next
            end
          rescue Exception => e
            logger.error "Error parsing friend names: #{e.message}"
          end 
          
          logger.error "Invalid recipient entry: #{entry}"
          recipient_errors << entry
        end
          
        @message_thread.to_ids_array= recipient_ids unless recipient_ids.empty?
        @message_thread.to_emails_array= recipient_emails unless recipient_emails.empty?
        @message_thread.to_phones_array= recipient_phones unless recipient_phones.empty?
        @message_thread.to_access_groups_array= recipient_access_groups unless recipient_access_groups.empty?
        
        unless recipient_errors.empty?
          flash[:error] = "Invalid recipient entr#{recipient_errors.size > 1 ? 'ies' : 'y'}: #{recipient_errors.join(', ')}"
          render :action => :new and return
        end
      end
      
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
  
      if (recipient_ids.nil? || recipient_ids.empty?) && 
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
        if params[:sms] && @sent_message.body && !@sent_message.body.blank?
          # make subject from first line of message
          @text_body = make_text_body(@sent_message.body)
          @text_body.each_line do |line|
            @message_thread.title = truncate_words(line,10)
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
    
    logger.debug "Sending message from #{current_user.id} to user ids=>#{recipient_emails.nil? ? '-' : recipient_ids.to_json}, emails=>#{recipient_emails.nil? ? '-' : recipient_emails.join(',')}, phones=>#{recipient_phones.nil? ? '-' : recipient_phones.join(',')}, groups=>#{recipient_access_groups.nil? ? '-' : recipient_access_groups.join(',')}"
    # Now we have all the ids, send the message to each one

    @body = @sent_message.body
    is_html = true

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

    unless recipient_ids.nil? || recipient_ids.empty?
      recipient_ids.uniq!
      recipient_ids.each do |recipient_id|
        logger.debug("Sending message #{@sent_message.id} to user id: #{recipient_id}")

        @message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
        @message.to_id= recipient_id
        @message.save!
      end
    end
    unless recipient_emails.nil? || recipient_emails.empty?
      recipient_emails.uniq!
      recipient_emails.each do |email|
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

    if @text_body.nil?
      if (recipient_phones && recipient_phones.size > 0) ||(recipient_access_groups && recipient_access_groups.size > 0)
        @text_body = make_text_body(@body)
      else
        @text_body = @body
      end
    end      

    unless recipient_phones.nil? || recipient_phones.empty?
      recipient_phones.uniq!
      
      recipient_phones.each do |sms|
        # translate SMS numbers to email
        contact = AccessContact.createSMSContact(sms)
        email = contact.to_email_recipient
        
        # don't deliver duplicate copies
        if all_sent_phones.include?(contact.destination)
          logger.debug("Skipping duplicate recipient email from sms number: #{sms}")
        else
          # remember this contact so we don't send multiple copies
          all_sent_phones << contact.destination
          
          logger.debug("Sending message  #{@sent_message.id} to phone number: #{sms}")
    
          # don't clutter the messages table with these...
          #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
          #@message.to_email= email
          #@message.save!
          begin
            UserNotifier.deliver_generic(email, @message_thread.title, @text_body, :html => false, :from => current_user.email )
          rescue Exception => e
            logger.error "Error sending email to #{email}: #{e.message}"
            flash[:error] = "Unable to send message to #{contact.destination}"
          end          
        end
      end
    end
    
    unless recipient_access_groups.nil? || recipient_access_groups.empty?
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
        unless group_contacts.nil? || group_contacts.empty?
          group_contacts.uniq!
         
          group_contacts.each do |contact|
            group_is_html = is_html
            group_body = @body
            # don't deliver duplicate copies
            if contact.contact_type == AccessContact.Type_Email && all_sent_emails.include?(contact.destination)
              logger.debug("Skipping duplicate recipient email in access group: #{contact.destination}")
            elsif contact.contact_type == AccessContact.Type_SMS && all_sent_phones.include?(contact.destination)
              logger.debug("Skipping duplicate recipient phone in access group: #{contact.destination}")
              group_is_html = false
              group_body = @text_body
            else
              # remember this contact so we don't send multiple copies
              all_sent_emails << contact.destination
              
              email = contact.to_email_recipient
              logger.debug("Sending message  #{@sent_message.id} to access group recipient: #{contact.destination}")
        
              # don't clutter the messages table with these...
              #@message = Message.new(:sent_message_id => @sent_message.id, :thread_id => @sent_message.thread_id)
              #@message.to_email= email
              #@message.save!
              begin
                UserNotifier.deliver_generic(email, @message_thread.title, group_body, :html => group_is_html, :from => current_user.email )
              rescue Exception => e
                logger.error "Error sending email to #{email}: #{e.message}"
                flash[:error] = "Unable to send message to #{contact.destination}"
              end          
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
      expand_access_group_contacts = false
      if (expand_access_group_contacts)
        recipient_ids = all_sent_user_ids
        recipient_emails = all_sent_emails
        recipient_phones = all_sent_phones
     end
      #######
    
      unless recipient_ids.nil?
        if use_alias
          # We expanded the sent user ids for "all", "team", "league" aliases... want to use an alias id for them in the DB
          #TODO: we can do better than to re-parse all the recipients here
          ids,is_alias =
              MessageThread.get_message_recipient_ids(params[:message_thread][:to], current_user, true)
          @message_thread.to_ids_array= ids
        else
          @message_thread.to_ids_array= recipient_ids
        end
      end
    
      @message_thread.to_emails_array= recipient_emails unless recipient_emails.nil?
      @message_thread.to_phones_array= recipient_phones unless recipient_phones.nil?
    
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

  def truncate_words(text, length = 30, end_string = '...')
    return if text.blank?
    text = ActionController::Base.helpers.strip_tags(text)
    words = text.split()
    if words.length > length
      words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    else
      text
    end
  end


  # Auto complete for addressing message to people in your 
  # friends list by name
  def auto_complete_for_friend_full_name
    if params[:message_thread][:to]
      search_name = params[:message_thread][:to].strip.downcase
      search_name_sql = search_name + '%'
      search_name_sql = '%' + search_name_sql if search_name.length > 3
      
      logger.debug "Auto complete for '#{search_name}'"
            
      if current_user.admin?
        @users = User.find(:all, :conditions => ["(LOWER(firstname) like ? or LOWER(lastname) like ?) and enabled = ?",search_name_sql,search_name_sql,true], :order => "lower(lastname) asc, lower(firstname) asc", :limit => 5)
        @groups = AccessGroup.find(:all, :conditions => ["lower(name) like ? and enabled=?",search_name_sql,true], :order => "lower(name)", :limit => 5)
      else
        @users = User.find(:all,
          :conditions => [
            "id in (?) and (LOWER(firstname) like ? or LOWER(lastname) like ?) and enabled = ?",
            current_user.mail_target_ids(),
            search_name_sql,
            search_name_sql,
            true
          ], :order => "lower(lastname) asc, lower(firstname) asc", :limit => 5)
  
        if current_user.team_staff?
          @groups = AccessGroup.find(:all, :conditions => ["lower(name) like ? and team_id=? and enabled=?",search_name_sql,current_user.team_id,true], :order => "lower(name)", :limit => 5)
        end
      end    
      
      search_name_sql= '%' + search_name_sql unless search_name_sql[0] == '%'
      
      threads = MessageThread.find(:all, :select => "distinct to_emails", :conditions => ["from_id=? and lower(to_emails) like ?",current_user.id,search_name_sql], :limit => 5)
      if threads && !threads.empty?
        @emails = Array.new
        threads.each do |thread|
          e = thread.to_emails_array.select {|email| email.downcase.include?(search_name)}
          if e && !e.empty?
            @emails << e
          end
        end
        @emails = @emails.flatten.uniq
        @emails = nil if @emails.empty?
      end
      
      if search_name =~ /\d/
        stripped = search_name.gsub(/[^\w]/,'')
        if /^d+$/.match(stripped)
          threads = MessageThread.find(:all, :select => "distinct to_phones", :conditions => ["from_id=? and to_phones like ?",current_user.id,search_name_sql], :limit => 5)
          if threads && !threads.empty?
            @phones = Array.new
            threads.each do |thread|
              p = thread.to_phones_array.select {|phone| phone.include?(search_name)}
              if p && !p.empty?
                @phones << p
              end
            end
            @phones = @phones.flatten.uniq
            @phones = nil if @phones.empty?
          end
        end
      end
      
      #choices = "<%= content_tag(:ul, @users.map { |u| content_tag(:li, h(u.full_name)) }) %>"
      #render :inline => choices
      logger.debug (render_to_string :partial => "messages/auto_complete_for_users")
      render :partial => "messages/auto_complete_for_users"
    end
  end


  def make_text_body(body)
    # strip tags for text message recipients
    # TODO: make this conditional
    text_body = ActionController::Base.helpers.strip_tags(body)    
    # normalize spaces
    text_body.squeeze!
    # remove leading and trailing whitespace
    text_body.strip!
    
    return text_body
  end
end
