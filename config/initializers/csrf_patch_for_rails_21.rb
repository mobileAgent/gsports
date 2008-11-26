# For more info see
# http://github.com/rails/rails/commit/099a98e9b7108dae3e0f78b207e0a7dc5913bd1a
# or
# http://weblog.rubyonrails.com/2008/11/18/potential-circumvention-of-csrf-protection-in-rails-2-1
Mime::Type.unverifiable_types.delete(:text)
