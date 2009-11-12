class MessagesController < BaseController
  
  protect_from_forgery :except => [:auto_complete_for_friend_full_name]
  
  # GET /messages
  # GET /messages.xml
  def index
    @thread_summary = true
    #@msgs = Message.paginate(:all, :conditions => ["to_id = ?", current_user.id], :order => "created_at DESC", :page => params[:page])
    @msgs = Message.user_threads(current_user.id).paginate(:page => params[:page], :order => "created_at DESC")
    render :action => 'inbox'
  end
  
  def thread
    @thread_summary = false
    thread = Message.find(params[:id])
    msgs = Message.message_thread(thread).owned_by(current_user.id)
    @unread_count = msgs.unread(current_user.id).size
    @msgs = msgs.paginate(:page => params[:page], :order => "created_at DESC")
    
    render :action => 'thread'
  end
  
  def thread_read
    thread = Message.find(params[:id])
    Message.message_thread(thread).unread(current_user.id).each do |msg|
      next if msg.to_id != current_user.id
      msg.read = 1
      msg.save!
    end
    redirect_to :action => 'thread', :id => params[:id]
  end
  
  # GET /messages/new
  def new
    # allow external-only emails to be sent for shared items
    shared_access_id = params[:shared_access_id] || (params[:message] ? params[:message][:shared_access_id] : nil)
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
    
    @message = Message.new(params[:message])
    logger.debug("built message #{@message.inspect} from params #{params.inspect}")
   
    if @shared_access
      @message.shared_access_id= @shared_access.id
      @shared_item = @shared_access.item
      @message.title = "#{current_user.full_name} sent you #{@shared_access.video? ? 'a video' : 'something'}: \"#{@shared_item.title}\""
    end
 
    if params[:re]
      @reply_to = Message.find(params[:re].to_i)
      @message.thread_id = @reply_to.thread_id || @reply_to.id
      @message.to_id= @reply_to.from_id == current_user.id ? @reply_to.to_id : @reply_to.from_id
      @message.title = @reply_to.title
    end
    
    if params[:to]
      begin
        @message.to_name= User.find(params[:to]).full_name
      rescue
        logger.debug("sked for a bad to_id #{params[:to]}")
      end
    end
    @message.title = params[:title] if params[:title]
    
    render :action => :new
  end
  
  # GET /messages/new links
  def update
    new
  end

  # POST /messages
  # POST /messages.xml
  def create
    shared_access_id = params[:shared_access_id] || (params[:message] ? params[:message][:shared_access_id] : nil)
    if shared_access_id
      logger.debug("Sharing item: #{shared_access_id}")
      @shared_access = SharedAccess.find(shared_access_id.to_i)
    end

    @message = Message.new(params[:message])

    if (params[:message][:to_name])
      begin
        recipient_ids,is_alias =
          Message.get_message_recipient_ids(params[:message][:to_name], current_user)
      rescue Exception => e
        logger.error "Error parsing friend names: #{e.message}"
      end
    else
      recipient_ids,is_alias = params[:message][:to_id],false
    end

    if (params[:message][:to_email])
      begin
        recipient_emails = Message.get_message_emails(params[:message][:to_email])
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
    if (report_id = params[:report][:id])
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
      @message = Message.new(params[:message])
      render :action => :new and return
    end

    logger.debug "Sending message from #{current_user.id} to #{recipient_emails.nil? ? '-' : recipient_ids.to_json}, #{recipient_emails.nil? ? '-' : recipient_emails.join(',')}"
    # Now we have all the ids, send the message to each one

    @body = @message.body
    is_html = false

    if @shared_access
      @shared_item = @shared_access.item
      is_html = true
      @body = render_to_string :partial => "messages/shared_item", :locals => { :body => @message.body }
    end

    @message = nil # pull out to scope for rescue render
    unless recipient_ids.nil?
      recipient_ids.uniq!
      recipient_ids.each do |recipient_id|
        logger.debug("Sending message to user id: #{recipient_id}")
        
        @message = Message.new(params[:message])
        @message.from_id= current_user.id
        @message.to_id= recipient_id
        if @message.title.nil? || @message.title.blank?
          @message.title= "(no subject)"
        end
        # override the body
        @message.body = @body
        @message.shared_access_id= @shared_access.id if @shared_access
        @message.save!
      end
    end
    unless recipient_emails.nil?
      recipient_emails.uniq!
      recipient_emails.each do |email|
        @message = Message.new(params[:message])
        @message.from_id= current_user.id
        @message.to_email= email
        @message.to_id= nil
        if @message.title.nil? || @message.title.blank?
          @message.title= "(no subject)"
        end
        # override the body
        @message.body= @body
        @message.shared_access_id= @shared_access.id if @shared_access
        # don't clutter the messages table with these...
        #@message.save!
        UserNotifier.deliver_generic(email, @message.title, @body, :html => is_html, :from => current_user.email )
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
              logger.debug("Sending message to access group user id: #{user.id}")
              
              # remember this user id so we don't send multiple copies
              all_sent_user_ids << user.id
              
              @message = Message.new(params[:message])
              @message.from_id= current_user.id
              @message.to_id= user.id
              @message.to_access_group_id= group.id
              if @message.title.nil? || @message.title.blank?
                @message.title= "(no subject)"
              end
              # override the body
              @message.body = @body
              @message.shared_access_id= @shared_access.id if @shared_access
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
              logger.debug("Sending message to access group recipient: #{contact.destination}")
        
              @message = Message.new(params[:message])
              @message.from_id= current_user.id
              @message.to_email= email
              @message.to_id= nil
              if @message.title.nil? || @message.title.blank?
                @message.title= "(no subject)"
              end
              # override the body
              @message.body= @body
              @message.shared_access_id= @shared_access.id if @shared_access
              # don't clutter the messages table with these...
              #@message.save!
              UserNotifier.deliver_generic(email, @message.title, @body, :html => is_html, :from => current_user.email )
            end
          end
        end
      end
    end
   
    # And finally drop a sent message for the sender
    logger.debug "Doing the sent message for #{current_user.id}"
    sent_message = SentMessage.new(params[:message])
    sent_message.from_id= current_user.id
    
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
      to_ids,uses_alias = (is_alias ? Message.get_message_recipient_ids(params[:message][:to_name],current_user,true) : [recipient_ids,false])
      sent_message.to_ids_array= to_ids
    end
    
    sent_message.to_emails_array= recipient_emails unless recipient_emails.nil?
    
    unless (recipient_access_groups.nil? || recipient_access_groups.empty?)
      group_ids = Array.new
      recipient_access_groups.each { |group| group_ids << group.id }
      logger.debug("Setting sent_message access groups to #{group_ids.join(',')}")
      sent_message.to_access_group_ids_array= group_ids
    end
    
    if sent_message.title.nil? || sent_message.title.blank?
      sent_message.title= "(no subject)"
    end
    sent_message.body= @body
    sent_message.shared_access_id= @shared_access.id if @shared_access
    sent_message.save!

    logger.debug "The sent message was saved"

    respond_to do |format|
      format.html { 
        flash[:notice] = "Your message was sent successfully."
        if @message.thread_id
          logger.debug "thread id #{@message.thread_id}, id #{@message.id}, read #{@message.real_thread_id}"
          redirect_to :action => 'thread', :id => @message.real_thread_id and return
        else
          redirect_to messages_url and return
        end
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
    @message.destroy
    @msgs = Message.inbox(current_user)
    respond_to do |format|
      format.html { render :action => 'inbox' }
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
    search_name = '%' + params[:message][:to_name] + '%'
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
