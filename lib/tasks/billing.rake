namespace :billing do
  desc "Notify users who have credit cards expiring this month"
  task :notify_expiring_cardholders => :environment do
    @cards = CreditCard.expiring
    @cards.each do |card|
      membership = card.membership
      if membership
        subscriptions = membership.subscriptions
        if subscriptions.any?
          user = subscriptions[0].user
          if user.enabled?
            MembershipNotifier.deliver_card_expiring(user.email,membership)
          end
        end
      end
    end
  end
end
