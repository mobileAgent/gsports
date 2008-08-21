#
# Bill each Membership when due
# This is meant to be run in the Rails environment with script/runner:
# ruby ./script/runner "RecurringBilling.bill_memberships"
#
class RecurringBilling
  SECONDS_PER_DAY = 86400
  PAYMENT_DUE_CYCLE = 0 # In days This needs to be 30 in Production

  # Put the log here
  @billing_logger = Logger.new("#{File.dirname(__FILE__)}/recurring_billing.log")
  #
  # Bill all memberships that have not been billed since the last cycle
  # 
  def self.bill_memberships
    @billing_logger.info "=======Starting billing #{Time.new}"

    members_due = find_memberships_to_bill
    @billing_logger.info "Found #{members_due.length} Memberships to bill"

    members_due.each {|mdue| 
      @billing_logger.info "Need to bill #{mdue.name}"
      # Bill the member 
      billing_result = mdue.bill_recurring

      if !billing_result.nil? && billing_result.success?
        @billing_logger.info "Successfully billed #{mdue.name}"
        MembershipNotifier.deliver_billing_success(mdue.address.email,mdue)
      else
        @billing_logger.info "Unable to bill #{mdue.name} response is nil" if billing_result.nil?
@billing_logger.info "Unable to bill #{mdue.name} response: #{billing_result.inspect}" if !billing_result.nil?
       # Need to check for a specific status here before we send an email to the membership
      end
    # Send an email
    }
  end 

  #
  # Get a list of memberships that need to be billed
  # Need to be billed is defined as it has been at least PAYMENT_DUE_CYCLE
  # days since they were last billed 
  # 
  def self.find_memberships_to_bill
    due = []
    mships = Membership.find :all
    @billing_logger.info "Found #{mships.length} memberships to process"
    mships.each {|m|
      due << m if ((time_diff_in_days(m.last_billed) >= PAYMENT_DUE_CYCLE) && (m.billing_method.eql?Membership::CREDIT_CARD_BILLING_METHOD))
    }
    due
  end

  #
  # What is the difference, in days, between the provided date and Time.now
  #
  def self.time_diff_in_days(time = Time.now)
    ((Time.now - time).round)/SECONDS_PER_DAY
  end
end  
