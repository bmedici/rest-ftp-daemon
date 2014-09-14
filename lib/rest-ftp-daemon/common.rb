module RestFtpDaemon

  class Common

  protected

    def initialize
      # Logger
      @logger = ActiveSupport::Logger.new APP_LOGTO, 'daily'
    end

    def id
    end

    def progname
    end

    def info message, level = 0
      # progname = "Job [#{id}]" unless id.nil?
      # progname = "Worker [#{id}]" unless worker_id.nil?
      @logger.add(Logger::INFO, "#{'  '*(level+1)} #{message}", progname)
    end


    def notify signal, error = 0, status = {}
      # Check if we have to notify or not
      url = get :notify
      info "Common.notify s[#{signal}] url[#{url}] e[#{error}] s#{status.inspect}"

      # Skip is not callback URL defined
      if url.nil?
        return
      end

      # Prepare notif body
      n = RestFtpDaemon::Notification.new
      n.job_id = id
      n.url = url
      n.signal = signal
      n.error = error.inspect
      n.status = status

      # Now, send the notification
      Thread.new(n) do |thread|
        n.send
      end

    end

  end
end
