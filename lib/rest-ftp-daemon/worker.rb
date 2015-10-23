module RestFtpDaemon
  class Worker
    include LoggerHelper
    attr_reader :logger

    if Settings.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    end

    def initialize wid
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers
      @log_worker_status_changes = true

      # Worker name
      @wid = wid

      # Set thread context
      Thread.current.thread_variable_set :wid, wid
      Thread.current.thread_variable_set :started_at, Time.now
      worker_status WORKER_STATUS_STARTING
    end

  protected

    def log_context
      {
        wid: @wid,
        jid: Thread.current.thread_variable_get(:jid),
      }
    end

    def start
      loop do
        begin
          work
        rescue StandardError => e
          log_error "WORKER EXCEPTION: #{e.inspect}"
          sleep 1
        end
      end
    end

    def worker_status status, job = nil
      # Update thread variables
      Thread.current.thread_variable_set :status, status
      Thread.current.thread_variable_set :updted_at, Time.now

      # Nothin' to log if "silent"
      return unless @log_worker_status_changes

      # Log this status change
      if job.is_a?(Job)
        log_info "#{status} - job[#{job.id}] status[#{job.status}] error[#{job.error}]"
      else
        log_info "#{status}"
      end
    end

    def worker_jid jid
      Thread.current.thread_variable_set :jid, jid
      Thread.current.thread_variable_set :updted_at, Time.now
    end

  end
end
