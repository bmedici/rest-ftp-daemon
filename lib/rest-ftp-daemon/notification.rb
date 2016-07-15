require 'api_auth'
require 'rest_client'

# Handle a notification POST using a dedicated thread
module RestFtpDaemon
  class Notification
    include BmcDaemonLib::LoggerHelper

    # Class options
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
      @logger = Shared::LoggerPool.instance.get :notify

      # Handle the notification
      log_info "initialized [#{@url}]"
      process
    end

  protected

    def process
      # Check context
      if @url.nil?
        log_error "skipping (missing url)", params
        return
      elsif @params[:event].nil?
        log_error "skipping (missing event)", params
        return
      end

      # Build body and extract job ID if provided
      flags = {
        id:       @params[:id].to_s,
        signal:   "#{NOTIFY_PREFIX}.#{@params[:event]}",
        error:    @params[:error],
        host:     Conf.host.to_s,
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
      uri = URI @url
      # uri = URI(rule[:relay])
      #http = Net::HTTP.new uri.host, uri.port

      # Prepare request
      request = RestClient::Request.new url: uri.to_s,
        method: :post,
        payload: JSON.pretty_generate(flags),
        headers: {
          content_type: :json,
          accept: :json,
          user_agent: Conf.generate(:user_agent),
          }

      # Execure request
      log_info "posting #{flags.to_json}"
      # response = http.post uri.path, data, headers
      response = request.execute

      # Log reponse body
      response_lines = response.body.lines
      if response_lines.size > 1
        human_size = Helpers.format_bytes(response.body.bytesize, "B")
        log_info "received [#{response.code}] #{human_size} (#{response_lines.size} lines)", response_lines
      else
        log_info "received [#{response.code}] #{response.body.strip}"
      end

      # Handle exceptions
      rescue Net::OpenTimeout => e
        log_error "Net::OpenTimeout: #{e.message}"

      rescue SocketError => e
        log_error "SocketError: #{e.message}"

      rescue StandardError => e
        log_error "UNHANDLED EXCEPTION: #{e.message}", e.backtrace
    end

    def log_prefix
     [nil, @jid, @id]
    end

  end
end
