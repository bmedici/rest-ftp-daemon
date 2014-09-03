require 'net/http'

module RestFtpDaemon
  class Notification
    attr_accessor :id
    attr_accessor :signal
    attr_accessor :error
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
    end

    def status key, val
      @status[key.to_s] = val
    end

    def notify!
      raise NotifImpossible unless @url
      raise NotifImpossible unless @signal
      raise NotifImpossible unless @signal
      raise NotifImpossible unless @status

      # Params
      params = {
        id: @id,
        host: get_hostname,
        signal: @signal,
      }

      # Add status only if present
      params["status"] = @status unless @status.empty?
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
