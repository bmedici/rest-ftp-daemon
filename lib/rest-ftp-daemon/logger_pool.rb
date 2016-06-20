require "logger"

module RestFtpDaemon

  # Logger interface class to access logger though symbolic names
  class LoggerPool
    include Singleton

    def initialize
      @loggers = {}
    end

    def get pipe
      @loggers[pipe] ||= create(pipe)
    end

    def create pipe
      # Compute file path / STDERR
      logfile = Conf[:logs][pipe] if Conf[:logs].is_a? Hash
      logfile ||= STDERR

      # Create the logger and return it
      logger = Logger.new(logfile, LOG_ROTATION)   #, 10, 1024000)
      logger.progname = pipe.to_s.downcase
      logger.formatter = Shared::LoggerFormatter

      # Finally return this logger
      logger
    end

  end
end
