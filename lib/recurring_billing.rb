#
# Bill each Membership when due
# This is meant to be run in the Rails environment with script/runner
#
class RecurringBilling
  SECONDS_PER_DAY = 86400
  PAYMENT_DUE_CYCLE = 3 # In days This needs to be 30 in Production

  # Put the log here
  @billing_logger = Logger.new("#{File.dirname(__FILE__)}/recurring_billing.log")
  #
  # Bill all memberships that have not been billed since the last cycle
  # 
  def self.bill_memberships
    @billing_logger.info "=======Starting billing #{Time.new}"

    members_due = find_memberships_to_bill
    @billing_logger.info "Found #{members_due.length} Memberships to bill"
    members_due.each {|mdue| @billing_logger.info "Need to bill #{mdue.name}"}

    # Bill the member
    # If successfull add a MembershipBillingHistory record
    # Log it
    # Send an email
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
      due << m if time_diff_in_days(m.last_billed) > PAYMENT_DUE_CYCLE
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
