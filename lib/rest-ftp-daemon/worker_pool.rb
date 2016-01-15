module RestFtpDaemon

  # Handles a pool of Worker objects
  class WorkerPool
    include LoggerHelper
    attr_reader :logger
    attr_reader :wid

    if Settings.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    end

    def initialize
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers

      # Prepare status hash and vars
      @statuses = {}
      @workers = {}
      @conchita = nil
      @mutex = Mutex.new

      # Identifiers generator
      @last_id = 0

      # Create worker threads
      create_threads
    end

    def worker_variables
      @workers.collect do |_wid, worker|
        vars = {}
        worker.thread_variables.each do |var|
          vars[var] = worker.thread_variable_get var
        end
        vars
      end
    end

    def worker_alive? wid
      @workers[wid] && @workers[wid].alive?
    end

  private

    def generate_id
      @mutex.synchronize do
        @last_id += 1
      end
      "w#{@last_id}"
    end

    def create_threads
      # Read configuration
      pools = (Settings.pools || {})

      # Minimum one worker on DEFAULT_POOL
      if !(pools.is_a? Hash)
        log_error "create_threads: one worker is the minimum possible number (#{pools.inspect}"
      end
      pools[DEFAULT_POOL] ||= 1

      # Create workers
      log_info "WorkerPool creating JobWorker's #{pools.inspect} + ConchitaWorker"
      pools.each do |pool, count|
        # Start worker threads for each pool
        log_info "WorkerPool creating JobWorker [#{pool}] x#{count}"
        count.times do
          wid = generate_id
          @workers[wid] = create_worker_thread wid, pool
        end
      end

      # Start conchita thread
      log_info "WorkerPool creating ConchitaWorker"
      @conchita = create_conchita_thread

    rescue StandardError => ex
      log_error "UNHANDLED EXCEPTION: #{ex.message}", ex.backtrace
    end

    def create_worker_thread wid, pool
      Thread.new wid do
        begin
          worker = JobWorker.new wid, pool
          log_info "JobWorker [#{wid}][#{pool}]: #{worker}"
        rescue StandardError => ex
          log_error "JobWorker EXCEPTION: #{ex.message}"
        end
      end
    end

    def create_conchita_thread
      Thread.new do
        begin
          worker = ConchitaWorker.new :conchita
          log_info "ConchitaWorker: #{worker}"
        rescue StandardError => ex
          log_error "ConchitaWorker EXCEPTION: #{ex.message}"
        end
      end
    end

    if Settings.newrelic_enabled?
      add_transaction_tracer :create_conchita_thread,     category: :task
      add_transaction_tracer :create_worker_thread,       category: :task
    end

  end
end
