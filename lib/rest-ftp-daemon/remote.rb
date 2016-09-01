# Handles transfers for Job class
module RestFtpDaemon
  class Remote
    include BmcDaemonLib::LoggerHelper

    # Class options
    attr_reader :logger
    attr_reader :log_prefix

    def initialize target, log_prefix, debug = false, ftpes = false
      # Init
      @target = target
      @ftpes = ftpes
      @debug = debug

      # Logger
      @log_prefix = log_prefix || {}
      @logger = BmcDaemonLib::LoggerPool.instance.get :transfer

      # Extract URL parts
      @url.user ||= "anonymous"

      # Annnounce object
      log_info "Remote.initialize [#{target.path}]"
      log_debug "Remote.initialize target[#{@target.inspect}]"
      prepare
    end

    def prepare
    end

    def connect
      # Debug mode ?
      return unless @debug
      puts
      puts "-------------------- SESSION STARTING -------------------------"
      puts "class\t #{myname}"
      puts "host\t #{@target.host}"
      puts "user\t #{@target.user}"
      puts "port\t #{@target.port}"
      puts "---------------------------------------------------------------"

    end

    def close
      # Debug mode ?
      return unless @debug
      puts "-------------------- SESSION CLOSING --------------------------"
    end

  private

    def extract_parent path
      return unless path.is_a? String
      m = path.match(/^(.*)\/([^\/]+)\/?$/)
      return m[1], m[2] unless m.nil?
    end

    def myname
      self.class.to_s
    end

  end
end
