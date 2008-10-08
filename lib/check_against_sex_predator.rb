#
# Check users' information against databases of sexual predators
# This is meant to be run in the Rails environment with script/runner:
# ruby ./script/runner "CheckAgainSexPredator.do_check"
# or custom rake task

class CheckAgainstSexPredator
  # Put the log here
  @warnning_sexpredater_logger = Logger.new("#{File.dirname(__FILE__)}/../log/warning_sexpredater.log")
  #
  # List all new memberships that have  been found in database of sexual predators
  #
  def self.do_check
    SorSearchLog.do_search
    @warnning_sexpredater_logger.info "=======Starting #{Time.new}"
    @sp_accounts = SorSearchLog.find(:all)
    @warnning_sexpredater_logger.info "Found #{@sp_accounts.size} accounts that need to be investigated"
    mail_message = []
    if @sp_accounts.size >0
      for sp_account in @sp_accounts
        @warnning_sexpredater_logger.info "Need to investigate #{sp_account.lastname + ', ' + sp_account.firstname}"
        mail_message << "need to check account: user_id = #{sp_account.user_id}, lastname = #{sp_account.lastname}, firstname = #{sp_account.firstname}, state =#{sp_account.state_name}, link =#{sp_account.link}"
      end
    end
     # Send an email
    UserNotifier.deliver_generic(ADMIN_EMAIL, "Nightly check against sex predator repos at #{Time.now}", "There are #{@sp_accounts.size} accounts that need to investigated against the sex predator repos.\n  Details: #{mail_message.join('\n')}")
  end
end
