class Promotion < ActiveRecord::Base
  validates_presence_of :promo_code
  validates_uniqueness_of :promo_code
  belongs_to :subscription_plan
   
   # Save the redcloth html on write
  before_save :generate_html

  protected
  def generate_html
    if self.content && !self.content.blank?
      self.html_content = RedCloth.new(self.content).to_html
    end
  end
end
