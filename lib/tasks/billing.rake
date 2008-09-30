namespace :billing do
  desc "Notify users who have credit cards expiring this month"
  task :notify_expiring_cardholders => :environment do
    @cards = CreditCard.expiring
    @cards.each do |card|
      membership = card.membership
      if membership
        user = membership.user
        if user.enabled?
          puts "Sending email to #{user.email}"
          MembershipNotifier.deliver_card_expiring(user.email,membership)
        end
      end
    end
  end
    
  desc "Notify users who have memberships expiring in 5 days"
  task :notify_expiring_memberships => :environment do
    date = 5.days.since
    puts "Sending membership for expirations for #{date.to_date}"
    @memberships = Membership.expires_on_date date
    @memberships.each do |membership|
      # only send this email if we are going to bill them via credit card
      user = membership.user
      if user.role.plan.cost > 0
        if membership.credit_card
          if user.enabled?
            puts "Sending email to #{user.email}"
            MembershipNotifier.deliver_membership_expiring(user.email,membership)
          end
        end
      else
        puts "Subscription is free, so nothing to alert the user about"
      end        
    end     
  end
  
end
