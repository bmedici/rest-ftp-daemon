module RestFtpDaemon

  # Handles a pool of Worker objects
  class WorkerPool
    include Shared::LoggerHelper
    attr_reader :logger
    attr_reader :wid

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

  protected

    def log_prefix
     [nil, nil, nil]
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
      pools = (Conf[:pools] || {})

      # Minimum one worker on DEFAULT_POOL
      if !(pools.is_a? Hash)
        log_error "create_threads: one worker is the minimum possible number (#{pools.inspect}"
      end
      pools[DEFAULT_POOL] ||= 1

      # Start JobWorkers threads for each pool
      pools.each do |pool, count|
        count.times do
          wid = generate_id
          @workers[wid] = create_thread JobWorker, wid, pool
        end
      end

      # Start ConchitaWorker and ReporterWorker
      @conchita = create_thread ConchitaWorker, :conchita

    rescue StandardError => ex
      log_error "UNHANDLED EXCEPTION: #{ex.message}", ex.backtrace
    end

      log_error "EXCEPTION: #{ex.message}", ex.backtrace
    end

    # def create_worker_thread wid, pool
    #   Thread.new wid do
    #     begin
    #       worker = JobWorker.new wid, pool
    #       #log_info "JobWorker [#{wid}][#{pool}]: #{worker}"
    #     rescue StandardError => ex
    #       log_error "JobWorker EXCEPTION: #{ex.message} #{e.backtrace}"
    #     end
    #   end
    # end

    def create_thread klass, wid, pool = nil
      log_info "spawning #{klass.name} [#{wid}] [#{pool}]"
      Thread.new do
        begin
          worker = klass.new wid, pool
        rescue StandardError => ex
          log_error "#{klass.name} EXCEPTION: #{ex.message}"
        end
      end
    end

    # NewRelic instrumentation
    if Conf.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      # add_transaction_tracer :create_conchita_thread,     category: :task
      add_transaction_tracer :create_thread,       category: :task
    end

  end
end
