require 'singleton'
require 'logger'

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
      logger = Logger.new(logfile, 'daily')   #, 10, 1024000)
      logger.progname = pipe.to_s.upcase

      # And the formatter
      logger.formatter = proc do |severity, datetime, progname, message|
        stamp = datetime.strftime("%Y-%m-%d %H:%M:%S")
        field_pipe = "%-#{LOG_PIPE_LEN.to_i}s" % progname
        "#{stamp}\t#{field_pipe}\t#{message}\n"
      end

      # Finally return this logger
      logger
    end

  private

  end
end
