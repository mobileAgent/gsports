class Membership < ActiveRecord::Base
   has_one :address, :as => :addressable, :dependent => :destroy
   has_many :subscriptions
   has_many :users, :through => :subscriptions
   has_many :membership_billing_histories, :order => "created_at DESC"
   has_one  :credit_card

   validates_presence_of :address

  CREDIT_CARD_BILLING_METHOD = "cc"
  INVOICE_BILLING_METHOD = "invoice"

  def last_billed
    membership_billing_histories.first.created_at
  end
#
# Bill this member
#
def bill_recurring

    return nil if credit_card.nil? # No credit card no billing (for now)
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :first_name => self.credit_card.first_name,
      :last_name => self.credit_card.last_name,
      :number => self.credit_card.number,
      :month => self.credit_card.month,
      :year => self.credit_card.year,
      :verification_value => self.credit_card.verification_value)

    return nil if !credit_card.valid?

    gateway = ActiveMerchant::Billing::PayflowGateway.new({
      :login => Active_Merchant_payflow_gateway_username,
      :password => Active_Merchant_payflow_gateway_password
                                                          })
    cost_for_gateway = (cost * 100).to_i
    response = gateway.purchase(cost_for_gateway, credit_card)
   
    logger.debug "Response from gateway #{@response.inspect} for #{cost_for_gateway}"
   
    if (response.success?)
      history = MembershipBillingHistory.new
      pf = response.params
      history.authorization_reference_number = "#{pf['pn_ref']}/#{pf['auth_code']}"
      history.payment_method = billing_method
      membership_billing_histories << history
      save
    end
    response # Let the caller get response 
end
end
