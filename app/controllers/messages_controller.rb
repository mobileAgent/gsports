class MessagesController < ApplicationController
  before_filter :login_required
  
  # GET /messages
  # GET /messages.xml
  def index
    case params[:box]
    when "sent"
      @msgs = Message.sent(current_user)
      render :action => 'sent'
    else
      @msgs = Message.inbox(current_user)
      render :action => 'inbox'
    end
    
    
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
    @message = Message.new(params[:message])
    @message.from_id = current_user.id
    respond_to do |format|
      if @message.save
        format.html { 
          flash[:notice] = "Your message was sent successfully."
          redirect_to messages_path()
        }
        format.js
      else
        format.html { render :action => "new" }
        format.js
      end
    end
  end
  
  
  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id])
    @message.destroy
    @msgs = Message.inbox(current_user)
    render :action => 'inbox'
  end
  
  

  def show
    @message = Message.find(params[:id])
    if (! (current_user.admin? || current_user.id == @message.to_id))
      redirect_to user_path(current_user)
      return
    end
  end

  def sent
  end
  
end
