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
      # Skip is not callback URL defined
      url = get :notify
      if url.nil?
        info "Skipping notification (no valid url provided) sig[#{signal}] e[#{error}] s#{status.inspect}"
        return
      end

      # Build notification
      n = RestFtpDaemon::Notification.new
      n.job_id = id
      n.url = url
      n.signal = signal
      n.error = error.inspect
      n.status = status

      # Now, send the notification
      info "Queuing notification key[#{n.key}] sig[#{signal}] url[#{url}]"
      Thread.new(n) do |thread|
        n.notify
      end

    end

  end
end
