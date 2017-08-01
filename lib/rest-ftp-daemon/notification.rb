require 'api_auth'
require 'rest_client'

# Handle a notification POST using a dedicated thread
module RestFtpDaemon
  class Notification
    include BmcDaemonLib::LoggerHelper
    include CommonHelpers

    # Class options
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
      @id = identifier(NOTIFY_IDENTIFIER_LEN)
      @jid = nil

      # Logger
      log_pipe :jobs

      # Handle the notification
      # log_info "initialized [#{@url}]"
      process
    end

  protected

    def process
      # Check context
      if @url.nil? || @url.to_s.empty?
        log_error "skipping (missing url)"
        return
      elsif @params[:signal].nil?
        log_error "skipping (missing signal)"
        return
      end

      # Import job id if present
      @jid = @params[:id]

      # Build body and extract job ID if provided
      flags = {
        id:       @params[:id].to_s,
        signal:   "#{NOTIFY_PREFIX}.#{@params[:signal]}",
        error:    @params[:error],
        host:     Conf.host.to_s,
        }
      if @params[:status].is_a?(Hash) && @params[:status].any?
        flags[:status] = @params[:status] 
      end

      unless @params[:message].nil?
        flags[:message] = @params[:message].to_s
      end

      # Spawn a dedicated thread
      Thread.new do
        post_notification flags
      end # end Thread
    end

    def post_notification flags
      # Prepare query
      uri = URI @url
      # uri = URI(rule[:relay])
      #http = Net::HTTP.new uri.host, uri.port

      # Prepare request
      request = RestClient::Request.new url: uri.to_s,
        timeout: NOTIFY_TIMEOUT,
        method: :post,
        payload: JSON.pretty_generate(flags),
        headers: {
          content_type: :json,
          accept: :json,
          user_agent: Conf.generate_user_agent,
          }

      # Execute request
      log_info "notify #{flags.to_json} to #{uri.to_s}"
      # response = http.post uri.path, data, headers
      response = request.execute

      # Log reponse body
      response_lines = response.body.lines
      if response_lines.size > 1
        human_size = format_bytes(response.body.bytesize, "B")
        log_info "received [#{response.code}] #{human_size} (#{response_lines.size} lines)", response_lines
      else
        log_info "received [#{response.code}] #{response.body.strip}"
      end

      # Handle exceptions
      rescue Net::OpenTimeout, SocketError,
        Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::ECONNRESET,
        RestClient::ResourceNotFound => e
        log_error "FAILED [#{e.class}] #{e.message}"

      rescue StandardError => e
        log_error "UNHANDLED ERROR [#{e.class.to_s}] #{e.message}", e.backtrace
    end

    def log_context
      {
      jid: @jid,
      id: @id,
      }
    end

  end
end