class Membership < ActiveRecord::Base
   has_one :address, :as => :addressable, :dependent => :destroy
   has_many :subscriptions
   has_many :users, :through => :subscriptions
   has_many :membership_billing_histories, :order => "created_at DESC"
   belongs_to :credit_card # fk: credit_card_id
   belongs_to :promotion # fk: promotion_id
   
  CREDIT_CARD_BILLING_METHOD = "cc"
  INVOICE_BILLING_METHOD = "invoice"
  FREE_BILLING_METHOD = "na"

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
  'MH' => 'Islands1',
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

  def last_billed
    return nil if membership_billing_histories.empty?
    membership_billing_histories.first.created_at
  end
  #
  # Bill this member
  #
  def bill_recurring
    return ActiveMerchant::Billing::PayflowResponse.new(false,"Nothing to charge: $0") if (cost.nil? || cost == 0)
    return ActiveMerchant::Billing::PayflowResponse.new(false,"Missing credit card information") if credit_card.nil? 

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
  
end
