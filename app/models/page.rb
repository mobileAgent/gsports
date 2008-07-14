class Page < ActiveRecord::Base

  # Save the redcloth html on write
  before_save :generate_html

  protected

  def generate_html
    self.html_content = RedCloth.new(self.content).to_html
  end

end
