module RestFtpDaemon
  class Remote
    include LoggerHelper
    attr_reader :logger
    attr_reader :log_context

    def initialize url, log_context, options = {}
      # Logger
      @log_context = log_context || {}
      @logger = RestFtpDaemon::LoggerPool.instance.get :jobs

      # Extract URL parts
      @url = url
      @url.user ||= "anonymous"

      # Annnounce object
      log_info "Remote.initialize [#{url.to_s}]"
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

    # def log_context
    #   @log_context
    # end

    def myname
      self.class.to_s
    end

    def debug_header
      # Output header to STDOUT
      puts
      puts "-------------------- SESSION STARTING -------------------------"
      #puts "job id\t #{@id}"
      #puts "source\t #{@source}"
      #puts "target\t #{@target}"
      puts "class\t #{myname}"
      #puts "class\t #{myname}"
      puts "host\t #{@url.host}"
      puts "user\t #{@url.user}"
      puts "port\t #{@url.port}"
      puts "options\t #{@options.inspect}"
      puts "---------------------------------------------------------------"
    end

  end
end
