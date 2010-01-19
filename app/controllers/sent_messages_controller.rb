class SentMessagesController < BaseController

  # GET /sent_messages
  # GET /sent_messages.xml
  def index
    @thread_summary = true
    @sent_messages = SentMessage.paginate :page => params[:page], :per_page => 20, :conditions => ["owner_deleted = 0 AND from_id = ?", current_user.id], :group => "thread_id", :order => "created_at DESC"
    render :action => 'outbox'
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
      flash[:info] = "#{c} message#{c==1?'has':'s have'} been deleted."
    else
      flash[:info] = "No messages were selected to be deleted"
    end
    respond_to do |format|
      format.html { redirect_to(sent_messages_url) }
      format.xml  { head :ok }
      format.js
    end
  end

end
