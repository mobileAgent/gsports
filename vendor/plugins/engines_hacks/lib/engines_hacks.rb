module Engines
  # Dear engines logger: Shut up. Sincerely, Mike.
  class << self
    ENGINES_LOGGER = Logger.new STDERR
    ENGINES_LOGGER.level= [RAILS_DEFAULT_LOGGER.level, Logger::INFO].max
    def logger
      ENGINES_LOGGER
    end
  end
end
