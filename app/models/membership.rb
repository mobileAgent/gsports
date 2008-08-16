class Membership < ActiveRecord::Base
   has_one :address, :as => :addressable, :dependent => :destroy
   has_many :subscriptions
   has_many :users, :through => :subscriptions
   has_many :membership_billing_histories, :order => "created_at DESC"
   has_one  :credit_card

  CREDIT_CARD_BILLING_METHOD = "cc"
  INVOICE_BILLING_METHOD = "invoice"

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
    membership_billing_histories.first.created_at
  end
#
# Bill this member
#
def bill_recurring
# Enable this once we really start encrypting CC numbers
#    crypt_key = EzCrypto::Key.with_password CC_CRYPT_PASSWORD,CC_CRYPT_SALT
#    decrypted_card_number = crypt_key.decrypt credit_card.number

    return nil if credit_card.nil? # No credit card no billing (for now)

    decrypted_card_number = credit_card.number # remove this and enable crypt lines once we start encrypting numbers
    credit_card = ActiveMerchant::Billing::CreditCard.new({
      :first_name => credit_card.first_name,
      :last_name => credit_card.last_name,
      :number => decrypted_card_number,
      :month => credit_card.month,
      :year => credit_card.year,
      :verification_value => credit_card.verification_value})

    gateway = ActiveMerchant::Billing::PayflowGateway.new({
      :login => Active_Merchant_payflow_gateway_username,
      :password => Active_Merchant_payflow_gateway_password
                                                          })
    cost_for_gateway = (cost * 100).to_i
    response = gateway.purchase(cost_for_gateway, credit_card)
   
    logger.debug "Response from gateway #{@response.inspect} for #{@user.full_name} at #{cost_for_gateway}"
   
    if (response.success?)
      history = MembershipBillingHistory.new
      pf = response.params
      history.authorization_reference_number = "#{pf['pn_ref']}/#{pf['auth_code']}"
      history.payment_method = billing_method
      membership_billing_histories << history
      save
    end
    response
end
end
