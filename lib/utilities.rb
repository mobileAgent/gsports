module Utilities
  
  def self.truncate_words(text, length = 30, end_string = '...')
    return if text.blank?
    text = ActionController::Base.helpers.strip_tags(text)
    words = text.split()
    if words.length > length
      words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    else
      text
    end
  end
  
  def self.count_words(text)
    return 0 if text.blank?
    words = ActionController::Base.helpers.strip_tags(text).split()
    words.length
  end

  def self.csv_split(s)
    if s
      s.split /,(?!(?:[^",]|[^"],[^"])+")/
    end
  end
    
  def self.readable_phone(phone)
    fmt = phone
    if phone && phone.length == 10
      fmt =phone.sub(/(\d{3})(\d{3})(\d{4})/,'(\1)\2-\3')
    end
    fmt
  end

  
end