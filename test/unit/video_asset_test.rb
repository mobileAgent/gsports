require 'test_helper'

class VideoAssetTest < ActiveSupport::TestCase
  
  fixtures :video_assets
  
  def test_save
    v = video_assets(:one)
    assert v.save!
  end

  def test_title_required
    v = video_assets(:one)
    v.title= nil
    assert ! v.valid?
  end

end
