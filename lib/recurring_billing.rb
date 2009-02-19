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
  # ALSO, prior to billing, renew any memberships that have expired, but not been canceled
  # 
  def self.bill_memberships
    
    # First, call renew_memberships. Any new renewals will then be billed by this function
    renew_memberships
    
    @billing_logger.info "=======Starting billing #{Time.new}"

    members_due = find_memberships_to_bill
    @billing_logger.info "Found #{members_due.length} Memberships to bill"

    billing_message = []
    billed_success = 0
    billed_error = 0
    members_due.each {|mdue| 
      begin
        @billing_logger.info "Need to bill #{mdue.user.id} #{mdue.name} $#{mdue.cost}"
        # Bill the member 
        billing_result = mdue.bill_recurring

        if billing_result.success?
          billed_success += 1
          begin
            billing_message << "Successfully billed #{mdue.user.id} #{mdue.name} #{membership_user_details(mdue)}"
            @billing_logger.info "Successfully billed #{mdue.user.id} #{mdue.name}"
            MembershipNotifier.deliver_billing_success(mdue.address.email,mdue) if !mdue.address.nil?
          rescue
            # be defensive about sending emails...
            @billing_logger.error "Error sending notification email to user #{mdue.user.id}: #{$!}"
          end
        else
          billed_error += 1
          begin
            billing_message << "Unable to bill #{mdue.user.id} #{mdue.name}: #{billing_result.message}. #{membership_user_details(mdue)}"
            @billing_logger.info "Unable to bill #{mdue.user.id} #{mdue.name} reason: #{billing_result.message}"
            MembershipNotifier.deliver_billing_failure(mdue.address.email,mdue, billing_result.message) if !mdue.address.nil?
          rescue
            # be defensive about sending emails...
            @billing_logger.error "Error sending notification email to user #{mdue.user.id}: #{$!}"
          end
        end
      rescue
        @billing_logger.error "* ERROR while billing membership ID #{mdue.id}: #{$!}"
        billing_message << "* ERROR billing membership ID #{mdue.id}: #{$!}"
      end
    }
    # Send an email
    UserNotifier.deliver_generic(ADMIN_EMAIL, "Nightly Billing for #{Time.now}", "Recurring billing completed.\n #{billed_success} billed successfully,\n #{billed_error} billing failed.\n Details:\n   #{billing_message.join("\r\n   ")}") 
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
    mships = Membership.active.find(:all, :conditions => ['billing_method = ? and cost > 0', Membership::CREDIT_CARD_BILLING_METHOD])
    @billing_logger.info "Found #{mships.length} memberships to process"
    mships.each {|m|
      due << m if (m.user.enabled && (m.last_billed.nil? || (time_diff_in_days(m.last_billed) >= PAYMENT_DUE_CYCLE)))
    }
    due
  end

  #
  # Bill all memberships that have not been billed since the last cycle
  # 
  def self.renew_memberships
    @billing_logger.info "=======Starting auto renewals #{Time.new}"

    renewals = find_memberships_to_renew
    @billing_logger.info "Found #{renewals.length} Memberships to renew"

    renewal_message = []
    renewal_success = 0
    renewal_error = 0
    renewals.each {|mexpired| 
      if !mexpired.promotion.nil? && mexpired.promotion.promo_code == 'GS7DAYSFREE'
        puts "* Excluding promotion GS7DAYSFREE from auto-renewal"
        @billing_logger.info "Auto-cancelling #{mexpired.user.id} #{mexpired.name} for promo #{mexpired.promotion.promo_code}"
        mexpired.cancel! 'Auto-cancelling GS7DAYSFREE promotion'
      elsif mexpired.user && mexpired.user.enabled
        @billing_logger.info "Need to renew #{mexpired.user.id} #{mexpired.name}"
        # Bill the member 
        new_membership = mexpired.renew

        if !new_membership.nil? && new_membership.active?
          renewal_success += 1
          renewal_message << "Successfully renewed #{mexpired.user.id} #{mexpired.name} #{membership_user_details(mexpired)}"
          @billing_logger.info "Successfully renewed #{mexpired.user.id} #{mexpired.name}"
        else
          renewal_error += 1
          renewal_message << "Unable to renew #{mexpired.user.id} #{mexpired.name} #{membership_user_details(mexpired)}"
          @billing_logger.info "Unable to renew #{mexpired.user.id} #{mexpired.name}" 
        end
      end
    }
    # Send an email
    UserNotifier.deliver_generic(ADMIN_EMAIL, "Nightly Renewals for #{Time.now}", "Automatic renewals completed.\n #{renewal_success} renewed successfully,\n #{renewal_error} renewed failed.\n Details:\n   #{renewal_message.join("\r\n   ")}") 
  end 

  #
  # Get a list of memberships that need to be renewed.
  # These are memberships that have expired and have not been explicitly canceled
  # 
  def self.find_memberships_to_renew
    Membership.expired
  end
  
  private 

  def self.membership_details(member)
    "#{APP_URL}/member.user.id"
  end
  #
  # What is the difference, in days, between the provided date and Time.now
  #
  def self.time_diff_in_days(time = Time.now)
    ((Time.now - time).round)/SECONDS_PER_DAY
  end

  def self.membership_user_details (member)
    if member.user.league_staff?
      "League: #{member.user.league_name} , Role: #{member.user.role.name}"
    else
      "Team: #{member.user.team.name} , Role: #{member.user.role.name}"
    end
  end
end  
