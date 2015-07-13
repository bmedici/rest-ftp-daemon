require "logger"

module RestFtpDaemon
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
      logfile = Settings.logs[pipe] if Settings.logs.is_a? Hash
      logfile ||= STDERR

      # Create the logger and return it
      logger = Logger.new(logfile, LOG_ROTATION)   #, 10, 1024000)
      logger.progname = pipe.to_s.upcase

      # And the formatter
      logger.formatter = proc do |severity, datetime, progname, messages|
        # Build common line prefix
        prefix = LOG_FORMAT_PREFIX % [
          datetime.strftime(LOG_FORMAT_TIME),
          severity,
          progname
        ]

        # If we have a bunch of lines, prefix them and send them together
        if messages.is_a? Array
          messages.map { |line| prefix + line + LOG_NEWLINE}.join
        else
          prefix + messages.to_s + LOG_NEWLINE
        end
      end

      # Finally return this logger
      logger
    end

  end
end
