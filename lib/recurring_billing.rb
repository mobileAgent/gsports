#
# Bill each Membership when due
# This is meant to be run in the Rails environment with script/runner:
# ruby ./script/runner "RecurringBilling.bill_memberships"
#
class RecurringBilling

  # Put the log here
  @billing_logger = Logger.new("#{File.dirname(__FILE__)}/../log/recurring_billing.log")
  #
  # Bill all memberships that have not been billed since the last cycle
  # 
  def self.bill_memberships
    @billing_logger.info "=======Starting billing #{Time.new}"

    members_due = find_memberships_to_bill
    @billing_logger.info "Found #{members_due.length} Memberships to bill"

    billing_message = []
    billed_success = 0
    billed_error = 0
    members_due.each {|mdue| 
      @billing_logger.info "Need to bill #{mdue.name}"
      # Bill the member 
      billing_result = mdue.bill_recurring

      if billing_result.success?
        billed_success += 1
        billing_message << "Successfully billed #{mdue.name} #{membership_user_details(mdue)}"
        @billing_logger.info "Successfully billed #{mdue.name}"
        MembershipNotifier.deliver_billing_success(mdue.address.email,mdue) if !mdue.address.nil?
      else
        billed_error += 1
        billing_message << "Unable to bill #{mdue.name}:#{billing_result.message}. #{membership_user_details(mdue)}"
        @billing_logger.info "Unable to bill #{mdue.name} reason: #{billing_result.message}" 
          MembershipNotifier.deliver_billing_failure(mdue.address.email,mdue, billing_result.message) if !mdue.address.nil?
      end
    }
    # Send an email
    UserNotifier.deliver_generic(ADMIN_EMAIL, "Nightly Billing for #{Time.now}", "Recurring billing completed.\n #{billed_success} billed successfully,\n #{billed_error} billing failed.\n Details: #{billing_message.join('\n')}") 
  end 

  #
  # Get a list of memberships that need to be billed
  # Need to be billed is defined as it has been at least PAYMENT_DUE_CYCLE
  # days since they were last billed 
  # 
  def self.find_memberships_to_bill
    due = []
    # Make sure we don't pull any zero-cost memberships, 
    # even though they should not have billing_method='cc'
    # mships = Membership.find_all_by_billing_method(Membership::CREDIT_CARD_BILLING_METHOD)
    mships = Membership.find(:all, :conditions => ['billing_method = ? and cost > 0', Membership::CREDIT_CARD_BILLING_METHOD])
    @billing_logger.info "Found #{mships.length} memberships to process"
    mships.each {|m|
      due << m if (m.last_billed.nil? || (time_diff_in_days(m.last_billed) >= PAYMENT_DUE_CYCLE))
    }
    due
  end

  def self.membership_details(member)
    "#{APP_URL}/member.users[0].id"
  end
  #
  # What is the difference, in days, between the provided date and Time.now
  #
  def self.time_diff_in_days(time = Time.now)
    ((Time.now - time).round)/SECONDS_PER_DAY
  end

  def self.membership_user_details (member)
    if member.users[0].league_staff?
      "League: #{member.users[0].league_name} , Role: #{member.users[0].role.name}"
    else
      "Team: #{member.users[0].team.name} , Role: #{member.users[0].role.name}"
    end
  end
end  
