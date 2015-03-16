require 'net/http'

module RestFtpDaemon
  class Notification
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

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :notify

      # Check context

      if url.nil?
        info "skipping (missing url): #{params.inspect}"
        return

      elsif params[:event].nil?
        info "skipping (missing event): #{params.inspect}"
        return

      else
        #info "created: OK"
        # info "created: #{params.class}"
        info "created #{params.inspect}"

      end

      # Params
      body = {
        id:       params[:id].to_s,
        signal:   "#{NOTIFY_PREFIX}.#{params[:event].to_s}",
        error:    params[:error],
        host:     Settings.host.to_s,
        }
      body[:status] = params[:status] if params[:status].is_a? Enumerable

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
        info "sending #{data}"

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
          info "received [#{response.code}] #{human_size} (#{response_lines.size} lines)", lines: response_lines
        else
          info "received [#{response.code}] #{response.body.strip}"
        end

      end

    end

  protected

    def info message, context = {}
      return if @logger.nil?

      # Inject context
      context[:id] = @id
      context[:origin] = self.class

      @logger.info_with_id message, context
    end

  end
end
