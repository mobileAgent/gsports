class MembershipNotifier < ActionMailer::Base
  default_url_options[:host] = APP_URL.sub('http://', '')
  include ActionController::UrlWriter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper 
  include BaseHelper
 
  def billing_success(email, membership)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "Your #{AppConfig.community_name} monthly membership fee has been billed"
    @sent_on     = Time.now
    @body[:message] = "#{membership.first_name}, your credit card ending in #{membership.credit_card.displayable_number} has been billed successfully. Thank You"
    @body[:url] = "#{APP_URL}
  end


  def billing_failure(email, membership)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "There was a problem billing your #{AppConfig.community_name} monthly membership fee"
    @sent_on     = Time.now
    @body[:message] = "#{membership.first_name}, There was a problem billing your credit card ending in ...#{membership.credit_card.displayable_number}. Please login and update your Profile biling information. Thank you!"
    @body[:url] = "#{APP_URL}"
  end

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    setup_sender_info
    @subject     = "[#{AppConfig.community_name} registration] "
    @sent_on     = Time.now
    @body[:user] = user
  end
 
  def setup_sender_info
    @from        = "The #{AppConfig.community_name} Team <#{AppConfig.support_email}>"   
  end
end
