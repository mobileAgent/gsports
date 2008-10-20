class SharedAccess < ActiveRecord::Base
  after_create :generate_key

  has_one :video_reel
  has_one :video_clip
  has_one :video_asset

  attr_protected :item_type, :key

  validates_presence_of :item_type, :item_id
  validates_uniqueness_of :key, :if => :id

  TYPE_REEL= 'vidr'
  TYPE_CLIP= 'vidc'
  TYPE_VIDEO= 'vida'

  def item=(item)
    @item= item
    unless item.nil?
      case item
      when VideoReel
        self.video_reel= item
      when VideoClip
        self.video_clip= item
      when VideoAsset
        self.video_asset= item
      end
    end
  end

  def item()
    @item= lookup_item if @item.nil?
    @item
  end

  def video?
    case item_type
    when TYPE_REEL, TYPE_CLIP, TYPE_VIDEO
      true
    else
      false
    end
  end

  def video_reel=(video)
    logger.debug "Sharing video reel #{video.id}"
    unless video.nil?
      self.item_type= TYPE_REEL
      self.item_id= video.id
      @item= video
    end
  end

  def video_clip=(video)
    logger.debug "Sharing video clip #{video.id}"
    unless video.nil?
      self.item_type= TYPE_CLIP
      self.item_id= video.id
      @item= video
    end
  end

  def video_asset=(video)
    logger.debug "Sharing video asset #{video.id}"
    unless video.nil?
      self.item_type= TYPE_VIDEO
      self.item_id= video.id
      @item= video
    end
  end

  protected

  def lookup_item
    if item_id
      case item_type
      when TYPE_VIDEO
        @item= VideoAsset.find item_id.to_i
      when TYPE_CLIP
        @item= VideoClip.find item_id.to_i
      when TYPE_REEL
        @item= VideoReel.find item_id.to_i
      end
      @item
    end
  end

  NUM_TO_ALPHABET= (("a".."z").to_a + ("1".."9").to_a)
  ALPHABET_SIZE= NUM_TO_ALPHABET.size

  def need_key?
   !id.nil? && (key.nil? || key.blank)
  end

  def generate_key
    if key.nil? || key.blank?
     rand_str= Array.new(8, '').collect{NUM_TO_ALPHABET[rand(ALPHABET_SIZE)]}.join
     self.key= rand_str + '-' + compress_num(id).rjust(4,'0')
     logger.debug "Generated key #{key}"
     save!
    end
    true 
  end

  # Routine to compress an integer into an base-35 alpha-numeric string
  def compress_num(num)
   alpha= ''
   begin
     idx= num % ALPHABET_SIZE
     alpha= NUM_TO_ALPHABET[idx] + alpha
     num= num / ALPHABET_SIZE
   end while (num > 0)
   alpha
  end

  # Routine to de-compress a base-35 alpha-numeric string into
  # its original integer representation
  def decompress_num(alpha)
   num= 0
   idx= 0
   alpha.reverse.each_char do |c| 
     num += NUM_TO_ALPHABET.index(c) * ALPHABET_SIZE**idx
     idx += 1
   end
   num
  end

end
