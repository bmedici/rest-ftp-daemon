module RestFtpDaemon
  class Notification
    include LoggerHelper
    attr_reader :logger

    attr_accessor :job_id
    attr_accessor :signal
    attr_accessor :error
    attr_accessor :message
    attr_accessor :status
    attr_accessor :url
    attr_accessor :job

    def initialize url, params
      # Remember params
      @url = url
      @params = params

      # Generate a random key
      @id = Helpers.identifier(NOTIFY_IDENTIFIER_LEN)
      @jid = nil

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :notify

      # Handle the notification
      log_info "initialized [#{@url}]"
      process
    end

  protected

    def process
      # Check context
      if @url.nil?
        log_info "skipping (missing url): #{@params.inspect}"
        return
      elsif @params[:event].nil?
        log_info "skipping (missing event): #{@params.inspect}"
        return
      end

      # Build body and extract job ID if provided
      flags = {
        id:       @params[:id].to_s,
        signal:   "#{NOTIFY_PREFIX}.#{@params[:event]}",
        error:    @params[:error],
        host:     Settings.host.to_s,
        }
      flags[:status] = @params[:status] if @params[:status].is_a? Enumerable
      flags[:message] = @params[:message].to_s unless @params[:message].nil?
      @jid = @params[:id]

      # Spawn a dedicated thread
      Thread.new do
        send flags
      end # end Thread
    end

    def send flags
      # Prepare query
      headers = {
        "Content-Type"  => "application/json",
        "Accept"        => "application/json",
        "User-Agent"    => NOTIFY_USERAGENT
         }
      data = flags.to_json

      # Send notification through HTTP
      uri = URI @url
      http = Net::HTTP.new uri.host, uri.port

      # Post notification, handle server response / multi-lines
      log_info "sending #{data}"
      response = http.post uri.path, data, headers
      response_lines = response.body.lines

      if response_lines.size > 1
        human_size = Helpers.format_bytes(response.body.bytesize, "B")
        log_info "received [#{response.code}] #{human_size} (#{response_lines.size} lines)", response_lines
      else
        log_info "received [#{response.code}] #{response.body.strip}"
      end

      # Handle exceptions
      rescue StandardError => ex
        log_error "EXCEPTION: #{ex.inspect}"

    end


    def log_context
      {
      id: @id,
      jid: @jid
      }
    end

  end
end
