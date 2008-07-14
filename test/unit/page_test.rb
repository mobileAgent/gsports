require 'test_helper'

class VideoClipTest < ActiveSupport::TestCase

  def test_validity
    p = pages(:one)
    assert p.valid?
  end
  
  def test_redcloth_applied_on_create
    p = Page.create :name => "Football Page", :permalink => "football", :content => "This *is* a test"
    assert (p.html_content.index('<strong>is</strong>') > 0)
  end
  
  def test_redcloth_applied_on_update
    p = Page.create :name => "Football Page", :permalink => "football", :content => "This is a test"
    p.content= "This *is* a test"
    p.save!
    assert (p.html_content.index('<strong>is</strong>') > 0)
  end
  
end
