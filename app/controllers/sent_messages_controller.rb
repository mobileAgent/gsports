class SentMessagesController < ApplicationController
  # GET /sent_messages
  # GET /sent_messages.xml
  def index
    @sent_messages = SentMessage.sent_by(current_user).find(:all, :order => 'created_at DESC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sent_messages }
    end
  end

  # GET /sent_messages/1
  # GET /sent_messages/1.xml
  def show
    @sent_message = SentMessage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sent_message }
    end
  end


  # DELETE /sent_messages/1
  # DELETE /sent_messages/1.xml
  def destroy
    @sent_message = SentMessage.find(params[:id])
    @sent_message.destroy

    respond_to do |format|
      format.html { redirect_to(sent_messages_url) }
      format.xml  { head :ok }
    end
  end
end
