class AccessContact < ActiveRecord::Base

  belongs_to :access_group

  Type_Email  = 'E'
  Type_SMS    = 'T'


  def contact_type_s()
    case contact_type
    when Type_Email
      'Email'
    when Type_SMS
      'SMS'
    end
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
  end




end

