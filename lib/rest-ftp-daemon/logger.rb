module RestFtpDaemon
  class Logger

    def initialize context, progname
      # Init
      @context = context
      @progname = progname

      # Compute file path
      logfile = Settings.logs[@context] if Settings.logs.is_a? Hash

      # Instantiate a logger if it's non-null
      @logger = ActiveSupport::Logger.new(logfile, 'daily') unless logfile.nil?
    end

    def info message, level = 0
      return if @logger.nil?

      stamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      progname = "%-#{DEFAULT_LOGS_PROGNAME_TRIM.to_i}s" % @progname
      line = "#{stamp} #{progname} \t#{'  '*(level+1)}#{message}"

      if @logger.nil?
        puts line
      else
        @logger.add(ActiveSupport::Logger::INFO, line)
      end
    end

  end
end
