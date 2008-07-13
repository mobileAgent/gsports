require 'test_helper'

class VideoClipTest < ActiveSupport::TestCase

  fixtures :video_clips
  
  def test_validity
    clip = video_clips(:one)
    assert clip.valid?
  end
  
end
