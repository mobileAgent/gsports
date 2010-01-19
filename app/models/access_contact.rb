class AccessContact < ActiveRecord::Base

  belongs_to :access_group

  Type_Email  = 'E'
  Type_SMS    = 'T'

  # http://www.mutube.com/projects/open-email-to-sms/gateway-list/
  SMS_Gateway_Domains = ['@teleflip.com','@message.alltel.com','@paging.acswireless.com','@txt.att.net','@bellsouth.cl','@myboostmobile.com','@mms.uscc.net','@sms.edgewireless.com','@messaging.sprintpcs.com','@tmomail.net','@mymetropcs.com','@messaging.nextel.com','@mobile.celloneusa.com','@qwestmp.com','@pcs.rogers.com','@msg.telus.com','@email.uscc.net','@vtext.com','@vmobl.com']

  def contact_type_s()
    case contact_type
    when Type_Email
      'Email'
    when Type_SMS
      'SMS'
    end
  end

  def to_email_recipient()
    case contact_type
    when Type_Email
      recipient = destination
    when Type_SMS
      l = Array.new
      SMS_Gateway_Domains.each do |domain|
        l << (destination + domain)
      end
      recipient = l.join(',') unless l.empty?
    end
    
    logger.debug ("AccessContact recipient: #{recipient}")
    
    recipient
  end


  def self.type_list()
    l = []
    
    c = AccessContact.new({:contact_type=>Type_Email})
    l << c
    
    c = AccessContact.new()
    c.contact_type = Type_SMS
    l << c
    
    l
  end



  def self.createEmailContact(address)
    self.createContact(Type_Email, address)
  end

  def self.createSMSContact(number)
    self.createContact(Type_SMS, number)
  end

  def self.createContact(contact_type, destination)
    ac = AccessContact.new()
    ac.contact_type = contact_type
    ac.destination = destination
    return ac
  end

end

