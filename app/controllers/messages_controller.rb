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
    to_names = params[:message][:to_name].split(',')
    to_ids = []
    to_names.each do |recipient|
      @message = Message.new(params[:message])
      @message.from_id= current_user.id
      @message.to_name= recipient
      to_ids << @message.to_id
      @message.save!
    end

    sent_message = SentMessage.new
    sent_message.from_id= current_user.id
    sent_message.title= params[:message][:title]
    sent_message.body= params[:message][:body]
    sent_message.to_ids_array= to_ids
    sent_message.save!
    
    respond_to do |format|
      format.html { 
        flash[:notice] = "Your message was sent successfully."
        redirect_to messages_path() and return
      }
      format.js
    end
    return
  rescue
    logger.debug("In rescue block ZZZ");
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
