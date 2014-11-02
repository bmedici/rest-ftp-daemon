require 'net/http'

module RestFtpDaemon
  class Notification < RestFtpDaemon::Common
    attr_accessor :job_id
    attr_accessor :signal
    attr_accessor :error
    attr_accessor :message
    attr_accessor :status
    attr_accessor :url
    attr_accessor :job
    attr_accessor :key

    def initialize url, params
      # Generate a random key
      key = Helpers.identifier(IDENT_NOTIF_LEN)

      # Logger
      @logger = RestFtpDaemon::Logger.new(:workers, "NOTIF #{@key}")

      # Call super
      super

    end

      # Check context
      if url.nil?
        info "skipping (missing url): #{params}"
        return
      elsif params[:signal].nil?
        info "skipping (missing signal): #{params}"
        return
      else
        # info "queuing: s[#{params[:signal]}] e[#{params[:error]}] u[#{url}]"
        info "queuing: #{params.inspect}"
      end

      # Params
      body = {
        id:       params[:id],
        signal:   params[:signal],
        error:    params[:error],
        host:     get_hostname,
        }
      body[:status] = params[:status] unless params[:status].empty? || params[:status].nil?

      # Send message in a thread
      Thread.new do |thread|
        # Prepare query
        uri = URI(url)
        headers = {"Content-Type" => "application/json",
                  "Accept" => "application/json"}

        # Post notification
        info "sending: #{body.inspect}"
        http = Net::HTTP.new(uri.host, uri.port)
        response = http.post(uri.path, body.to_json, headers)

        # info "notify reply: #{response.body.strip}"
        info "reply: #{response.body.strip}"
      end

    end

  protected

    def get_hostname
      `hostname`.chomp
    end

  end
end
