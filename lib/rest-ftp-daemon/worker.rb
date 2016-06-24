module RestFtpDaemon
  class Worker
    include Shared::LoggerHelper
    attr_reader :logger
    attr_reader :pool
    attr_reader :wid

    def initialize wid, pool = nil
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers
      @log_worker_status_changes = true

      # Set thread context
      @pool = pool
      @wid = wid
      Thread.current.thread_variable_set :pool, pool
      Thread.current.thread_variable_set :wid, wid
      Thread.current.thread_variable_set :started_at, Time.now
      worker_status WORKER_STATUS_STARTING

      # Ask worker to init itself, and return if there are errors
      if worker_init_result = worker_init
        log_error "#{self.class.name} worker_init: #{worker_init_result}", @config
      else
        # We're ok, let's start out loop
        start_loop
      end
  end

  protected

    # Worker methods prototypes
    def worker_init
    end
    def worker_after
    end
    def worker_process
    end
    def worker_config
    end

    def log_prefix
     [
      Thread.current.thread_variable_get(:wid),
      Thread.current.thread_variable_get(:jid),
      nil
      ]
    end

    def start_loop
      log_info "#{self.class.name} ready", {
        wid: @wid,
        pool: @pool,
        timeout: @timeout
        }
      log_info "#{self.class.name} starting", @config

      loop do
        begin
          # Do the hard work
          worker_process

          # Do the cleaning/sleeping stuff
          worker_after

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
        log_info "status [#{status}] on job[#{job.id}] status[#{job.status}] error[#{job.error}]"
      else
        log_info "status [#{status}]"
      end
    end

    def worker_jid jid
      Thread.current.thread_variable_set :jid, jid
      Thread.current.thread_variable_set :updated_at, Time.now
    end

  private

    def load_config wid
      # My debug
      @debug = (Conf.at :debug, wid) == true
      @log_worker_status_changes = @debug

      # My configuration
      @config = Conf[wid]
      if !@config.is_a? Hash
        return log_info "#{self.class.name}: missing #{wid}/* configuration"
      elsif @config[:timer].nil?
        return log_info "#{self.class.name}: missing #{wid}/timer value"
      end
    end

    # NewRelic instrumentation
    if Conf.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :worker_process,    category: :task
    end

  end
end
