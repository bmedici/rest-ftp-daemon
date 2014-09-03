module RestFtpDaemon
  class Notification < RestFtpDaemon::Common
    attr_accessor :job_id
    attr_accessor :signal
    attr_accessor :error
    attr_accessor :message
    attr_accessor :status
    attr_accessor :url
    attr_accessor :job

    def initialize
    #def initialize(job, signal, error, status)
      # Grab params
      #@job = job
      # @signal = signal
      # @error = error
      # @status = status
      @status = {}
      @error = 0
      @message = nil

      # Generate a random key
      @key = SecureRandom.hex(2)

      # Call super
      super

    end

    # def status key, val
    #   @status[key.to_s] = val
    # end

    def send
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

      # Add status only if present
      params["status"] = @status unless @status.empty?
      params["message"] = @message unless @message.to_s.blank?

      # Log this notification
      info "send [#{@key}] #{params.inspect}", 1

      # Prepare query
      uri = URI(@url)
      headers = {"Content-Type" => "application/json",
                "Accept" => "application/json"}

      # Post the notification
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.post(uri.path, params.to_json, headers)

      info "send [#{@key}] #{response.body.strip}", 1
    end

  protected

    def get_hostname
      `hostname`.chomp
    end

  end
end
