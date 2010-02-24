require 'vendor/plugins/community_engine/app/models/user_notifier'

class UserNotifier < ActionMailer::Base
  default_url_options[:host] = APP_URL.sub('http://', '')
  include ActionController::UrlWriter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper  
  include BaseHelper
      
   # http://www.mutube.com/projects/open-email-to-sms/gateway-list/
  @@SMS_Gateway_Domains = Array['@teleflip.com','@message.alltel.com','@paging.acswireless.com','@txt.att.net','@bellsouth.cl','@myboostmobile.com','@mms.uscc.net','@sms.edgewireless.com','@messaging.sprintpcs.com','@tmomail.net','@mymetropcs.com','@messaging.nextel.com','@mobile.celloneusa.com','@qwestmp.com','@pcs.rogers.com','@msg.telus.com','@vtext.com','@vmobl.com']
  
  def self.sms_to_email(phone_number)
    recipient = nil
    if phone_number && phone_number.match(/\d/)
      stripped = phone_number.gsub(/[^\w]/,'')
      a = @@SMS_Gateway_Domains.collect{ |domain| stripped + domain }
      recipient = a.join(',') unless a.empty?
    end
    recipient
  end
  
  def signup_invitation(email, user, message)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "#{user.full_name} would like you to join #{AppConfig.community_name}!"
    @sent_on     = Time.now
    @body[:user] = user
    @body[:url]  = user.generate_invite_url    
    @body[:message] = message
  end

  def friendship_request(friendship)
    setup_sender_info
    @recipients  = "#{friendship.friend.email}"
    @subject     = "#{friendship.user.full_name} would like to be friends with you on #{AppConfig.community_name}!"
    @sent_on     = Time.now
    @body[:url]  = friendship.generate_url
    @body[:user] = friendship.friend
    @body[:requester] = friendship.user
  end

  def comment_notice(comment)
    @recipients  = "#{comment.recipient.email}"
    setup_sender_info
    @subject     = "#{comment.user.full_name} has something to say to you on #{AppConfig.community_name}!"
    @sent_on     = Time.now
    @body[:url]  = comment.generate_commentable_url
    @body[:user] = comment.recipient
    @body[:comment] = comment
    @body[:commenter] = comment.user
  end
  
  def follow_up_comment_notice(user, comment)
    @recipients  = "#{user.email}"
    setup_sender_info
    @subject     = "#{comment.user.full_name} has commented on a #{comment.commentable_type} that you also commented on. [#{AppConfig.community_name}]"
    @sent_on     = Time.now
    @body[:url]  = comment.generate_commentable_url
    @body[:user] = user
    @body[:comment] = comment
    @body[:commenter] = comment.user
  end  

  def new_forum_post_notice(user, post)
     @recipients  = "#{user.email}"
     setup_sender_info
     @subject     = "#{post.user.full_name} has posted in a thread you are monitoring [#{AppConfig.community_name}]."
     @sent_on     = Time.now
     @body[:url]  = "#{forum_topic_url(:forum_id => post.topic.forum, :id => post.topic, :page => post.topic.last_page)}##{post.dom_id}"
     @body[:user] = user
     @body[:post] = post
     @body[:author] = post.user
   end

  def signup_notification(user)
    setup_email(user)
    @subject    += "Please activate your new #{AppConfig.community_name} account"
    @body[:url]  = "#{APP_URL}/users/activate/#{user.activation_code}"
  end

  def post_recommendation(name, email, post, message = nil, current_user = nil)
    @recipients  = "#{email}"
    @sent_on     = Time.now
    setup_sender_info
    @subject     = "Check out this story on #{AppConfig.community_name}"
    content_type "text/html"
    @body[:name] = name  
    @body[:title]  = post.title
    @body[:post] = post
    @body[:signup_link] = (current_user ? current_user.generate_invite_url : "#{APP_URL}/signup" )
    @body[:message]  = message
    @body[:url]  = user_post_url(post.user, post)
    @body[:description] = truncate_words(post.post, 100, @body[:url] )     
  end
  
  def activation(user)
    setup_email(user)
    @subject    += "Your #{AppConfig.community_name} account has been activated!"
    @body[:url]  = "#{APP_URL}"
  end
  
  def welcome(user)
    setup_email(user)
    @subject += "Your account has been created!"
    @body[:url]  = "#{APP_URL}"
  end

  def roster_invite(options = {})
    @roster_entry  = options[:to]
    @coach         = options[:from]

    setup_sender_info
    
    content_type "text/html"
    
    @recipients  = "#{@roster_entry.email}"
    @subject     = "#{AppConfig.community_name} invitation"
    @sent_on     = Time.now

    @body[:roster_entry] = @roster_entry
    @body[:coach] = @coach

    @body[:url]  = "#{APP_URL}/?roster_invite_key=#{@roster_entry.reg_key}"
  end
  
  def reset_password(user)
    setup_email(user)
    @subject    += "#{AppConfig.community_name} User information"
  end

  def forgot_username(user)
    setup_email(user)
    @subject    += "#{AppConfig.community_name} User information"
  end

  def new_message(sent_message,email)
    @recipients   = "#{email}"
    setup_sender_info
    @subject      = "#{sent_message.sender.full_name} has sent you a message on #{AppConfig.community_name}!"
    @sent_on      = Time.now
    @body[:url]   = "#{APP_URL}/messages/thread/#{sent_message.thread_id}"
    @body[:from]  = sent_message.sender
    @body[:title] = sent_message.message_thread.title
  end

  def new_message_sms(sent_message,phonenumber) 
    content_type ('text/plain')
    setup_sender_info
    
    @recipients = "#{UserNotifier::sms_to_email(phonenumber)}"   
    @subject = ''
    @sent_on = Time.now
    
    msg_a = "#{sent_message.sender.full_name} has sent you a message on #{AppConfig.community_name}."
    msg_b = " Login to view: #{APP_URL}"
    msg = msg_a + msg_b
    if msg.length > 160
      msg_a = "#{sent_message.sender.firstname} has sent you a message on #{AppConfig.community_name}."      
      if msg_a.length + msg_b.length > 160
        msg = (msg_a + msg_b).slice(0,157).concat('...')
      else
        msg = msg_a + msg_b
      end
    end
    @body[:message] = msg
  end

  def generic(email, subject, message, options={})
    o_html = options[:html]
    o_from = options[:from]
    o_reply_to = options[:reply_to]
    
    setup_sender_info
    content_type (o_html ? "text/html" : "text/plain")
    @recipients  = "#{email}"
    @subject     = "#{subject}"
    @sent_on     = Time.now
    @body[:message] = message

    if o_from
      @from = o_from
      @reply_to = o_from
    end
    if o_reply_to
      @reply_to = o_reply_to
    end
  end

  def generic_html(email, subject, message)
    o_from = options[:from]
    o_reply_to = options[:reply_to]
    
    content_type "text/html"
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "#{subject}"
    @sent_on     = Time.now
    @body[:message] = message

    if o_from
      @from = o_from
      @reply_to = o_from
    end
    if o_reply_to
      @reply_to = o_reply_to
    end
  end
  
  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    setup_sender_info
    @subject     = "[#{AppConfig.community_name} registration] "
    @sent_on     = Time.now
    @body[:user] = user
  end
  
  def setup_sender_info
    @from        = "The #{AppConfig.community_name} Team <#{AppConfig.support_email}>"
  end
  
end
