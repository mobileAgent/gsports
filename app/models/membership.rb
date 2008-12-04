class Membership < ActiveRecord::Base
  has_one :address, :as => :addressable, :dependent => :destroy
  # has_one :subscription
  # has_one :user, :through => :subscription
  has_many :membership_billing_histories, :order => "created_at DESC"
  belongs_to :credit_card # fk: credit_card_id
  belongs_to :purchase_order # fk: purchase_order_id  
  belongs_to :promotion # fk: promotion_id
  has_one :membership_cancellation
  belongs_to :user
   
  CREDIT_CARD_BILLING_METHOD = "cc"
  INVOICE_BILLING_METHOD = "invoice"
  FREE_BILLING_METHOD = "na"
  
  STATUS_CANCELED = "c"
  STATUS_RENEWED = "r"
  STATUS_ACTIVE = "a"

  STATES = {
    'AL' => 'Alabama',
    'AK' => 'Alaska',
    'AS' => 'America Samoa',
    'AZ' => 'Arizona',
    'AR' => 'Arkansas',
    'CA' => 'California',
    'CO' => 'Colorado',
    'CT' => 'Connecticut',
    'DE' => 'Delaware',
    'DC' => 'District of Columbia',
    'FM' => 'Micronesia1',
    'FL' => 'Florida',
    'GA' => 'Georgia',
    'GU' => 'Guam',
    'HI' => 'Hawaii',
    'ID' => 'Idaho',
    'IL' => 'Illinois',
    'IN' => 'Indiana',
    'IA' => 'Iowa',
    'KS' => 'Kansas',
    'KY' => 'Kentucky',
    'LA' => 'Louisiana',
    'ME' => 'Maine',
    'MH' => 'Marshall Islands',
    'MD' => 'Maryland',
    'MA' => 'Massachusetts',
    'MI' => 'Michigan',
    'MN' => 'Minnesota',
    'MS' => 'Mississippi',
    'MO' => 'Missouri',
    'MT' => 'Montana',
    'NE' => 'Nebraska',
    'NV' => 'Nevada',
    'NH' => 'New Hampshire',
    'NJ' => 'New Jersey',
    'NM' => 'New Mexico',
    'NY' => 'New York',
    'NC' => 'North Carolina',
    'ND' => 'North Dakota',
    'OH' => 'Ohio',
    'OK' => 'Oklahoma',
    'OR' => 'Oregon',
    'PW' => 'Palau',
    'PA' => 'Pennsylvania',
    'PR' => 'Puerto Rico',
    'RI' => 'Rhode Island',
    'SC' => 'South Carolina',
    'SD' => 'South Dakota',
    'TN' => 'Tennessee',
    'TX' => 'Texas',
    'UT' => 'Utah',
    'VT' => 'Vermont',
    'VI' => 'Virgin Island',
    'VA' => 'Virginia',
    'WA' => 'Washington',
    'WV' => 'West Virginia',
    'WI' => 'Wisconsin',
    'WY' => 'Wyoming'
  }

  named_scope :canceled, 
      :conditions => ['status=?',STATUS_CANCELED]
  named_scope :active,
      :conditions => ['status=? and (expiration_date is null or expiration_date > ?)', STATUS_ACTIVE, Time.now]
  named_scope :expired, 
      :conditions => ['status=? and expiration_date is not null and expiration_date < ?', STATUS_ACTIVE, Time.now]
  named_scope :expires_on_date, 
      lambda { |date| { :conditions => ['status=? and date(expiration_date)=date(?)', STATUS_ACTIVE, date] } }
      
  named_scope :for_team, 
      lambda { |team| 
        { :conditions => {:user_id => User.team_admin(team.id).collect {|u| u.id} } }
      }
  
  
  def active?
    status==STATUS_ACTIVE && (expiration_date.nil? || expiration_date > Time.now)
  end

  def canceled?
    status==STATUS_CANCELED
  end

  def expired?
    status==STATUS_ACTIVE && !expiration_date.nil? && expiration_date < Time.now
  end

  def renewed?
    status==STATUS_RENEWED
  end
  
  def last_billed
    return nil if membership_billing_histories.empty?
    membership_billing_histories.first.created_at
  end
  #
  # Bill this member
  #
  def bill_recurring
    return ActiveMerchant::Billing::PayflowResponse.new(false,"Membership canceled") if (canceled?)
    return ActiveMerchant::Billing::PayflowResponse.new(false,"Nothing to charge: $0") if (cost.nil? || cost == 0)
    return ActiveMerchant::Billing::PayflowResponse.new(false,"Missing credit card information") if credit_card.nil? 
    return ActiveMerchant::Billing::PayflowResponse.new(false,"Expired credit card") if credit_card.expired?

    # convert to ActiveMerchant credit card for validation
    am_credit_card = self.credit_card.to_active_merchant_cc
    unless am_credit_card.valid?
      return ActiveMerchant::Billing::PayflowResponse.new(false,am_credit_card.validate.to_s)
    end    

    gateway = ActiveMerchant::Billing::PayflowGateway.new(
        :login => Active_Merchant_payflow_gateway_username,
        :password => Active_Merchant_payflow_gateway_password,
        :partner => Active_Merchant_payflow_gateway_partner)
                                                          
    cost_for_gateway = (cost * 100).to_i
    response = gateway.purchase(cost_for_gateway, am_credit_card)
   
    logger.debug "Response from gateway #{@response.inspect} for #{cost_for_gateway}"
   
    if (response.success?)
      history = MembershipBillingHistory.new
      pf = response.params
      history.authorization_reference_number = "#{pf['pn_ref']}/#{pf['auth_code']}"
      history.payment_method = billing_method
      history.credit_card = self.credit_card
      membership_billing_histories << history
      save
    end
    response # Let the caller get response 
  end
  
  def renew
    
    # make a copy of this membership, using the current plan cost
    new_membership = Membership.new self.attributes
    new_membership.id = nil
    new_membership.promotion = nil
    new_membership.expiration_date = nil
    new_membership.created_at = nil
    new_membership.updated_at = nil
    
    # use the current price for the subscription plan
    new_membership.cost = @user.role.plan.cost
    if @billing_method.nil? || @billing_method == FREE_BILLING_METHOD
      new_membership.billing_method = CREDIT_CARD_BILLING_METHOD
    else
      new_membership.billing_method = @billing_method
    end
    
    if new_membership.save
      # set the status to renewed for this membership
      begin
        self.status=STATUS_RENEWED
        save!
      rescue ActiveRecord::RecordNotSaved
        logger.error "Record not saved!"
      end
      
      # return the new membership
      return new_membership
    else 
      logger.error "Unable to renew membership for user #{@user.id} #{@user.full_name}"
      return nil
    end
  end

  def cancel!(reason=nil)
    if !canceled?
      logger.info "Cancelling membership for #{@user.id}: #{@user.email}"

      cancellation= MembershipCancellation.new
      cancellation.reason= reason
      cancellation.membership= self

      self.status= STATUS_CANCELED
      self.membership_cancellation = cancellation
      self.save!
    end
    true  
  end
  
end
