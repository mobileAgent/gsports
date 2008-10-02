class MembershipNotifier < ActionMailer::Base
  default_url_options[:host] = APP_URL.sub('http://', '')
  include ActionController::UrlWriter
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper 
  include BaseHelper
 
  def billing_success(email, membership)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "[#{AppConfig.community_name}] Your monthly membership fee has been billed"
    @sent_on     = Time.now
    @body[:message] = "Hi #{membership.name},\n\nYur credit card ending in #{membership.credit_card.displayable_number} has been billed successfully. \nThank you for continuing your #{AppConfig.community_name} membership."
    @body[:url] = "#{APP_URL}"
  end


  def billing_failure(email, membership, reason)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "[#{AppConfig.community_name}]There was a problem billing your monthly membership fee"
    @sent_on     = Time.now
    @body[:message] = "Hi #{membership.name},\n\nThere was a problem billing your credit card: #{reason}. Please login and update your Profile billing information.\n\nThank you!"
    @body[:url] = "#{APP_URL}"
  end

  def card_expiring(email, membership)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "[#{AppConfig.community_name}] News about your account"
    @sent_on     = Time.now
    @body[:message] = "Hi #{membership.name},\n\nThe credit card used for your account (ending in #{membership.credit_card.displayable_number}) is going to expire soon.\nPlease login and update your Profile billing information!\n\nThank you!"
    @body[:url] = "#{APP_URL}"
  end

  def membership_expiring(email, membership)
    setup_sender_info
    @recipients  = "#{email}"
    @subject     = "[#{AppConfig.community_name}] News about your account"
    @sent_on     = Time.now
    @body[:message] = "Hi #{membership.name},\n\nYour promotional membership is going to expire on #{membership.expiration_date.to_date}.\n\nNo action is required at this time to continue using #{AppConfig.community_name}. On that date, you will be billed the monthly cost for your membership on your credit card (ending in #{membership.credit_card.displayable_number}).\n\nIf you would like to cancel your membership, please login before your account expires to prevent the first month's billing.\n\nThank you!"
    @body[:url] = "#{APP_URL}"
  end

  protected
  def setup_email(user)
    setup_sender_info
    @sent_on = Time.now
  end
 
  def setup_sender_info
    @from = "The #{AppConfig.community_name} Team <#{AppConfig.support_email}>"   
  end
end
