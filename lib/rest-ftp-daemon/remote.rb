module RestFtpDaemon

  # Handles transfers for Job class
  class Remote
    include Shared::LoggerHelper
    attr_reader :logger
    attr_reader :log_prefix

    def initialize url, log_prefix, options = {}
      # Logger
      @log_prefix = log_prefix || {}
      @logger = RestFtpDaemon::LoggerPool.instance.get :jobs

      # Extract URL parts
      @url = url
      @url.user ||= "anonymous"

      # Annnounce object
      log_info "Remote.initialize [#{url}]"
    end

    def connect
      # Debug mode ?
      debug_header if @debug
    end

    def close
      # Debug mode ?
      puts "-------------------- SESSION CLOSING --------------------------" if @debug
    end

  private

    def myname
      self.class.to_s
    end

    def debug_header
      # Output header to STDOUT
      puts
      puts "-------------------- SESSION STARTING -------------------------"
      puts "class\t #{myname}"
      puts "host\t #{@url.host}"
      puts "user\t #{@url.user}"
      puts "port\t #{@url.port}"
      puts "options\t #{@options.inspect}"
      puts "---------------------------------------------------------------"
    end

  end
end
