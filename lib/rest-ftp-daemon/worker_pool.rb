module RestFtpDaemon
  class WorkerPool

    attr_reader :wid

    if Settings.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    end

    def initialize number_threads
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers

      # Check parameters
      raise "at least one worker is needed to continue (#{number_threads} is less than one)" if number_threads < 1

      # Prepare status hash and vars
      @statuses = {}
      @workers = {}
      @conchita = nil
      @mutex = Mutex.new
      @counter = 0
      @timeout = (Settings.transfer.timeout rescue nil) || DEFAULT_WORKER_TIMEOUT

      # Create worker threads
      info "WorkerPool creating worker threads [#{number_threads}] timeout [#{@timeout}]s"
      create_worker_threads number_threads

      # Create conchita thread
      info "WorkerPool creating conchita thread"
      create_conchita_thread
    end

    def worker_variables
      @workers.collect do |wid, worker|
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

    def create_worker_threads n
# FIXME counter instead of upto ?
      n.times do
        # Increment counter
        @mutex.synchronize do
          @counter +=1
        end

        # Create a dedicated thread for this worker
        wid = "w#{@counter}"
        @workers[wid] = create_worker_thread wid
      end
    end

    def create_worker_thread wid
      Thread.new wid do
        # Set thread context
        Thread.current.thread_variable_set :wid, wid
        Thread.current.thread_variable_set :started_at, Time.now
        worker_status :starting

        # Start working
        loop do
          begin
            work
          rescue Exception => ex
            puts "WORKER UNEXPECTED CRASH: #{ex.message}", lines: ex.backtrace
            sleep 1
          end
        end

        # We should never get here
      end
    end

    def create_conchita_thread
      Thread.new do
        begin
          @conchita = Conchita.new
        rescue Exception => e
          info "CONCHITA EXCEPTION: #{e.inspect}"
        end
      end
    end

    def work
      # Wait for a job to come into the queue
      worker_status :waiting
      info "waiting for a job"
      job = $queue.pop

      # Prepare the job for processing
      worker_status :working
      worker_jid job.id
      info "working"
      job.wid = Thread.current.thread_variable_get :wid

      # Processs this job protected by a timeout
      Timeout::timeout(@timeout, RestFtpDaemon::JobTimeout) do
        job.process
      end

      # Processing done
      worker_status :finished
      info "finished"
      worker_jid nil
      job.wid = nil

      # Increment total processed jobs count
      $queue.counter_inc :jobs_processed

    rescue RestFtpDaemon::JobTimeout => ex
      info "JOB TIMED OUT", lines: ex.backtrace
      worker_status :timeout
      job.oops_you_stop_now ex unless job.nil?
      sleep 1

    rescue Exception => ex
      info "UNHDNALED EXCEPTION: #{ex.message}", lines: ex.backtrace
      worker_status :crashed
      job.oops_after_crash ex unless job.nil?
      sleep 1

    else
      # Clean job status
      worker_status :free
      job.wid = nil

    end

  protected

    def info message, context = {}
      return if @logger.nil?

      # Forward to logger
      @logger.info_with_id message,
        wid: Thread.current.thread_variable_get(:wid),
        jid: Thread.current.thread_variable_get(:jid),
        origin: self.class.to_s
    end

    def worker_status status
      Thread.current.thread_variable_set :status, status
      Thread.current.thread_variable_set :updted_at, Time.now
    end

    def worker_jid jid
      Thread.current.thread_variable_set :jid, jid
      Thread.current.thread_variable_set :updted_at, Time.now
    end

    if Settings.newrelic_enabled?
      add_transaction_tracer :create_worker_thread, :category => :task
      add_transaction_tracer :work, :category => :task
    end

  end
end
