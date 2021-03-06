class SentMessagesController < BaseController

  # GET /sent_messages
  # GET /sent_messages.xml
  def index
    @thread_summary = true
    @sent_messages = SentMessage.paginate :page => params[:page], :per_page => 20, :conditions => ["owner_deleted = 0 AND from_id = ?", current_user.id], :group => "thread_id", :order => "created_at DESC"
    render :action => 'outbox'
  end

  def admin_delete
    c = 0
    if current_user.admin?
      if params[:id]
        @sent_message = SentMessage.find(params[:id].to_i)
        Message.find(:all, :conditions => {:sent_message_id => @sent_message.id}).each do |msg|
          next if msg.deleted
          msg.deleted = 1
          msg.save
          c += 1
        end
        @sent_message.owner_deleted = 1
        @sent_message.save
      end
    end
    if c > 0
      flash[:info] = "#{c} message#{c==1?' has':'s have'} been deleted."
    else
      flash[:info] = "No messages were deleted"
    end

    respond_to do |format|
      format.html { redirect_to(url_for(:controller => 'messages', :action => 'thread', :id => @sent_message.thread_id)) }
      format.js
    end
  end
  
  def delete_multi
    c=0
    if params[:thread_id_check]
      params[:thread_id_check].each do |id|
        thread = MessageThread.find(id)
        
        thread.sent_messages.sent_by(current_user).each do |sent|
          next if sent.owner_deleted
          sent.owner_deleted = 1
          sent.save
          c += 1
        end
  
        thread.messages.for_user(current_user.id).each do |msg|
          next if msg.deleted
          msg.deleted = 1
          msg.save!
          c += 1
        end
      end
      flash[:info] = "#{c} message#{c==1?' has':'s have'} been deleted."
    else
      flash[:info] = "No messages were selected to be deleted"
    end
    respond_to do |format|
      format.html { redirect_to(sent_messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

  def show
    @sent_message = SentMessage.find(params[:id])

    if @sent_message.from_id != current_user.id
      # get the TO: user message
      @message = @sent_message.user_message(current_user)

      # make sure the user has access to this message
      if @message.nil? && !current_user.admin? 
        redirect_to user_path(current_user)
        return
      else
        # Sir, gentlemen do not read other people's mail.
        # My good man, they do, but they don't mark it as 'read' when they do.
        if @message && @message.unread? && current_user.id == @message.to_id
          @message.read= true
          @message.save!
        end
      end
    end
    
    respond_to do |format|
      format.html # => show.html.haml
      format.js # => show.rjs 
    end
  end

end
