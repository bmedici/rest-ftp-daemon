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

    def initialize
      @status = {}
      @error = 0
      @message = nil

      # Generate a random key
      key = Helpers.identifier(IDENT_NOTIF_LEN)

      # Logger
      @logger = RestFtpDaemon::Logger.new(:workers, "NOTIF #{@key}")

      # Call super
      super

    end


    # def status key, val
    #   @status[key.to_s] = val
    # end

    def notify
      # Check context
      raise NotificationMissingUrl unless @url
      raise NotificationMissingSignal unless @signal
      #sraise NotifImpossible unless @status

      # Params
      params = {
        id: @job_id,
        host: get_hostname,
        signal: @signal,
        error: @error,
        }

      params["status"] = @status unless @status.empty?
      params["message"] = @message unless @message.to_s.blank?

      info "notify params: #{params.inspect}"

      uri = URI(@url)
      headers = {"Content-Type" => "application/json",
                "Accept" => "application/json"}

      http = Net::HTTP.new(uri.host, uri.port)
      response = http.post(uri.path, params.to_json, headers)
    end

  protected

    def get_hostname
      `hostname`.chomp
    end

  end
end
