require 'test_helper'

class VideoActivityTest < ActiveSupport::TestCase

  fixtures :video_assets, :video_clips, :video_reels

  def new_clip(public = true)
    v = video_clips(:one).clone
    v.public_video= public
    v
  end
    
  def test_new_public_clip_should_make_activity
    v = new_clip
    v.save!
    a = Activity.last
    assert(a && a.item_id == v.id && a.item_type == v.class.to_s)
  end
  
  def test_new_private_clip_should_not_make_activity
    v = new_clip(false)
    v.save!
    a = Activity.last
    assert(a.nil? || a.item_id != v.id || a.item_type != v.class.to_s)
  end

  def test_private_clip_becoming_public_should_make_activity
    v = new_clip(false)
    v.save!
    v.public_video= true
    v.save!
    a = Activity.last
    assert(a && a.item_id == v.id && a.item_type == v.class.to_s)
  end

  def new_reel(public = true)
    v = video_reels(:one).clone
    v.public_video= public
    v
  end

  def test_new_public_reel_should_make_activity
    v = new_reel(true)
    v.save!
    a = Activity.last
    assert(a && a.item_id == v.id && a.item_type == v.class.to_s)
  end
  
  def test_new_private_reel_should_not_make_activity
    v = new_reel(false)
    v.save!
    a = Activity.last
    assert(a.nil? || a.item_id == v.id || a.item_type == v.class.to_s)
  end

  def test_private_reel_becoming_public_should_make_activity
    v = new_reel(false)
    v.save!
    v.public_video= true
    v.save
    a = Activity.last
    assert(a && a.item_id == v.id && a.item_type == v.class.to_s)
  end

  def new_asset(status = 'ready', public = true)
    v = video_assets(:one).clone
    v.public_video= public
    v.video_status= status
    v
  end

  def test_new_public_video_should_make_activity
    v = new_asset('ready',true)
    v.save!
    a = Activity.last
    assert(a && a.item_id == v.id && a.item_type == v.class.to_s)
  end
  
  def test_new_private_video_should_not_make_activity
    v = new_asset('ready',false)
    v.save!
    a = Activity.last
    assert(a.nil? || a.item_id != v.id || a.item_type != v.class.to_s)
  end

  def test_new_public_video_becoming_ready_should_make_activity
    v = new_asset('queued',true)
    v.save!
    v.video_status = 'ready'
    v.save!
    a = Activity.last
    assert(a && a.item_id == v.id && a.item_type == v.class.to_s)
  end

  def test_deleted_video_should_leave_history
    v = new_asset
    dockey = 'thisisafakedockey'
    v.dockey= dockey
    v.save!
    vid = v.id
    v.destroy
    dv = DeletedVideo.find_by_dockey(dockey)
    assert(dv && dv.dockey == dockey && dv.video_id = vid)
  end

end
