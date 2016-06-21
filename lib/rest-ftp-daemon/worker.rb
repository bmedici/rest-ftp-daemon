module RestFtpDaemon
  class Worker
    include Shared::LoggerHelper
    attr_reader :logger

    def initialize wid, pool = nil
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers
      @log_worker_status_changes = true

      # Worker name
      @pool = pool

      # Set thread context
      Thread.current.thread_variable_set :pool, pool
      Thread.current.thread_variable_set :wid, wid
      Thread.current.thread_variable_set :started_at, Time.now
      worker_status WORKER_STATUS_STARTING

      # Load corker conf
      load_config
    end

  protected

    def wait_according_to_config
      # Sleep for a few seconds
      worker_status WORKER_STATUS_WAITING
      sleep @config[:timer] if @config.is_a? Hash
    end

    def log_prefix
     [
      Thread.current.thread_variable_get(:wid),
      Thread.current.thread_variable_get(:jid),
      nil
      ]
    end

    def work
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
      Thread.current.thread_variable_set :updated_at, Time.now

      # Nothin' to log if "silent"
      return unless @log_worker_status_changes

      # Log this status change
      if job.is_a?(Job)
        log_info "Worker status[#{status}] on job[#{job.id}] status[#{job.status}] error[#{job.error}]"
      else
        log_info "Worker status[#{status}]"
      end
    end

    def worker_jid jid
      Thread.current.thread_variable_set :jid, jid
      Thread.current.thread_variable_set :updated_at, Time.now
    end

  private

    def load_config
      # My debug
      @debug = (Conf.at :debug, wid) == true
      @log_worker_status_changes = @debug

      # My configuration
      @config = Conf[wid]
      if !@config.is_a? Hash
        return log_info "#{self.class.name}: missing #{wid}.* configuration"
      elsif @config[:timer].nil?
        return log_info "#{self.class.name}: missing #{wid}.timer value"
      end
    end

    # NewRelic instrumentation
    if Conf.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :work,       category: :task
    end

  end
end
