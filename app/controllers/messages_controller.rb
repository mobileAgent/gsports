class MessagesController < ApplicationController
  
  before_filter :login_required
  protect_from_forgery :except => [:auto_complete_for_friend_full_name]
  
  # GET /messages
  # GET /messages.xml
  def index
    @msgs = Message.inbox(current_user)
    render :action => 'inbox'
  end
  
  # GET /messages/new
  def new  
    @message = Message.new()
    @message.to_id = params[:to] if params[:to]
    @message.title = params[:title] if params[:title]
  end


  # POST /messages
  # POST /messages.xml
  def create
    recipient_ids =
      Message.get_message_recipient_ids(params[:message][:to_name], current_user)
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
    sent_message.to_ids_array= recipient_ids
    sent_message.save!

    logger.debug "The sent message was saved"

    respond_to do |format|
      format.html { 
        flash[:notice] = "Your message was sent successfully."
        redirect_to messages_url and return
      }
      format.js
    end
  rescue
    logger.debug("In rescue block ZZZ: " + $! );
    respond_to do |format|
      format.html { render :action => "new" }
      format.js
    end
  end
  
  
  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id])
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
