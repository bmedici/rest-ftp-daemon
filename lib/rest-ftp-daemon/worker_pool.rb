module RestFtpDaemon

  # Handles a pool of Worker objects
  class WorkerPool
    include BmcDaemonLib::LoggerHelper
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

    # Class options
    attr_reader :logger
    attr_reader :wid

    def initialize
      # Logger
      @logger = BmcDaemonLib::LoggerPool.instance.get :workers

      # Prepare status hash and vars
      @statuses = {}
      @workers = {}
      @mutex = Mutex.new

      # Identifiers generator
      @last_worker_id = 0

      # Create worker threads
      create_threads
    end

    def worker_variables
      vars = {}
      @workers.collect do |wid, worker|
        vars[wid] = thread_variables worker
      end
      vars
    end

    def worker_alive? wid
      @workers[wid] && @workers[wid].alive?
    end

  protected

    def log_prefix
     [nil, nil, nil]
    end

  private

    def thread_variables thread
      vars = {}
      thread.thread_variables.each do |var|
        vars[var] = thread.thread_variable_get var
      end
      vars
    end

    def next_worker_id
      @mutex.synchronize do
        @last_worker_id += 1
      end
      "w#{@last_worker_id}"
    end

    def create_threads
      # Read configuration or initialize with empty hash
      pools = Conf.at[:pools]
      pools = {} unless pools.is_a? Hash

      # Minimum one worker on DEFAULT_POOL
      if !(pools.is_a? Hash)
        log_error "create_threads: one JobWorker is the minimum (#{pools.inspect}"
      end
      log_info "WorkerPool creating all workers with #{pools.to_hash.inspect}"

      # Start ConchitaWorker and ReporterWorker
      create_thread :conchita, ConchitaWorker
      create_thread :reporter, ReporterWorker

      # Start JobWorkers threads, ensure we have at least one worker in default pool
      pools[DEFAULT_POOL] ||= 1
      pools.each do |pool, count|
        count.times do
          wid = next_worker_id
          create_thread(wid, TransferWorker, pool)
        end
      end

    rescue StandardError => ex
      log_error "EXCEPTION: #{ex.message}", ex.backtrace
    end

    def create_thread wid, klass, pool = nil
      # Spawn thread and add it to my index
      log_info "spawning #{klass.name} wid[#{wid}] pool[#{pool}]"
      @workers[wid] = Thread.new do
        begin
          worker = klass.new wid, pool
          sleep 0.1
        rescue StandardError => ex
          log_error "#{klass.name} EXCEPTION: #{ex.message}"
        end
      end
    end

    # NewRelic instrumentation
    add_transaction_tracer :create_thread, category: :task

  end
end
