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
      # Generate a random key
      @id = Helpers.identifier(NOTIFY_IDENTIFIER_LEN)
      @jid = nil

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :notify

      # Check context
      if url.nil?
        log_info "skipping (missing url): #{params.inspect}"
        return
      elsif params[:event].nil?
        log_info "skipping (missing event): #{params.inspect}"
        return
      end

      # Build body and extract job ID if provided
      body = {
        id:       params[:id].to_s,
        signal:   "#{NOTIFY_PREFIX}.#{params[:event].to_s}",
        error:    params[:error],
        host:     Settings.host.to_s,
        }
      body[:status] = params[:status] if params[:status].is_a? Enumerable
      body[:message] = params[:message].to_s unless params[:message].nil?
      @jid = params[:id]
      log_info "initialized"


      # Send message in a thread
      Thread.new do |thread|
        # Prepare query
        uri = URI(url)
        headers = {
          'Content-Type'  => 'application/json',
          'Accept'        => 'application/json',
          'User-Agent'    => "#{APP_NAME} - #{APP_VER}"
           }
        data = body.to_json
        log_info "sending #{data}"


        # Prepare HTTP client
        http = Net::HTTP.new uri.host, uri.port
        # http.initialize_http_header({'User-Agent' => APP_NAME})

        # Post notification
        response = http.post uri.path, data, headers

        # Handle server response / multi-lines
        response_lines = response.body.lines

        if response_lines.size > 1
          human_size = Helpers.format_bytes(response.body.bytesize, "B")
          #human_size = 0
          log_info "received [#{response.code}] #{human_size} (#{response_lines.size} lines)", response_lines
        else
          log_info "received [#{response.code}] #{response.body.strip}"
        end

      end

    end

  protected

    def log_context
      {
      id: @id,
      jid: @jid
      }
    end

  end
end
