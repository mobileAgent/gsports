require File.dirname(__FILE__) + '/../test_helper'

class AthleteOfTheWeekTest < ActiveSupport::TestCase
  
  fixtures :posts, :users, :categories

  def test_photo_extraction
    # Grab the post fixture and use the id to get it
    # as an aotw
    p = posts(:not_funny_post)
    a = AthleteOfTheWeek.find(p.id)
    photo_url = a.image_thumbnail_for_post
    puts "url #{photo_url}"
    assert_not_nil photo_url
    assert photo_url.index("feature")
  end

  def test_name_for_post
    p = posts(:not_funny_post)
    a = AthleteOfTheWeek.find(p.id)
    # Author is kyle, a league admin for league two
    # so we want the league name here
    assert a.logo_title == leagues(:two).name
  end
  
  def test_team_or_league_logo_for_post
    p = posts(:not_funny_post)
    a = AthleteOfTheWeek.find(p.id)
    # Author is kyle, a league admin for league two
    # so we want the league logo here
    logo_src = a.logo_thumbnail_for_post
    assert_not_nil logo_src
    assert logo_src.index(leagues(:two).avatar.public_filename(:thumb))
  end
    
end
