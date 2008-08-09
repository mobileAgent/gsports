require File.dirname(__FILE__) + '/../test_helper'

class AthleteOfTheWeekTest < ActiveSupport::TestCase
  
  fixtures :posts, :users, :categories

  def test_photo_extraction
    # Grab the post fixture and use the id to get it
    # as an aotw
    p = posts(:not_funny_post)
    g = AthleteOfTheWeek.find(p.id)
    photo_url = g.image_thumbnail_for_post
    assert_not_nil photo_url
    assert photo_url.index("thumb")
  end
    

end
