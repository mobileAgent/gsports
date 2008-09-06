class MessagesController < BaseController
  
  protect_from_forgery :except => [:auto_complete_for_friend_full_name]
  
  # GET /messages
  # GET /messages.xml
  def index
    @msgs = Message.paginate(:all, :conditions => ["to_id = ?", current_user.id], :order => "created_at DESC", :page => params[:page])
    render :action => 'inbox'
  end
  
  # GET /messages/new
  def new
    unless (current_user.admin? || current_user.team_staff? || current_user.league_staff?)
      if current_user.accepted_friendships.size == 0
        flash[:info] = "You need to have some friends to send messages to!"
        redirect_to accepted_user_friendships_path(current_user) and return
      end
    end
    
    @message = Message.new(params[:message])
    logger.debug("built message #{@message.inspect} from params #{params.inspect}")
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
    if (params[:message][:to_name])
      recipient_ids,is_alias =
        Message.get_message_recipient_ids(params[:message][:to_name], current_user)
    else
      recipient_ids,is_alias = params[:message][:to_id],false
    end

    if (recipient_ids.nil? || recipient_ids.size == 0)
      logger.debug("There were no recipients found, sending back to new")
      flash[:info] = "You can only send messages to your friends"
      @message = Message.new(params[:message])
      render :action => :new and return
    end
    logger.debug "Sending message from #{current_user.id} to #{recipient_ids.to_json}"
    # Now we have all the ids, sent the message to each one
    @message = nil # pull out to scope for rescue render
    recipient_ids.each do |recipient_id|
      @message = Message.new(params[:message])
      @message.from_id= current_user.id
      @message.to_id= recipient_id
      @message.save!
    end

    # And finally drop a sent message for the sender
    logger.debug "Doing the sent message for #{current_user.id}"
    sent_message = SentMessage.new(params[:message])
    sent_message.from_id= current_user.id
    to_ids,uses_alias = (is_alias ? Message.get_message_recipient_ids(params[:message][:to_name],current_user,true) : recipient_ids)
    sent_message.to_ids_array= to_ids
    sent_message.save!

    logger.debug "The sent message was saved"

    respond_to do |format|
      format.html { 
        flash[:notice] = "Your message was sent successfully."
        redirect_to messages_url and return
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
    if (! (current_user.admin? || current_user.id == @message.to_id))
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
    @friend_ids = Friendship.find(:all, :conditions => ['user_id = ? and friendship_status_id = ?',current_user.id,FriendshipStatus[:accepted].id]).collect(&:friend_id) 
    if @friend_ids.nil? || @friend_ids.size == 0
      render :inline => '' and return
    end
    search_name = '%' + params[:message][:to_name] + '%'
    @users = User.find(:all, :conditions => ["id in (?) and (LOWER(firstname) like ? or LOWER(lastname) like ?)", @friend_ids,search_name,search_name], :order => "lastname asc, firstname asc", :limit => 10)
    choices = "<%= content_tag(:ul, @users.map { |u| content_tag(:li, h(u.full_name)) }) %>"    
    render :inline => choices
  end

end
