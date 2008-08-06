my_formats = {:game_date  => "%Y-%m-%d",:readable => "%d %B, %Y"}
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(my_formats)
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(my_formats)
