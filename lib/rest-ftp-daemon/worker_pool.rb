

module RestFtpDaemon
  class WorkerPool

    attr_reader :wid

    def initialize number_threads
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers


      # Check parameters
      raise "A thread count of #{number_threads} is less than one" if number_threads < 1

      # Prepare status hash and vars
      @statuses = {}
      @workers = {}
      @mutex = Mutex.new
      @counter = 0

      # Create worker threads
      info "WorkerPool initializing with #{number_threads} workers"
      create_worker_threads number_threads

    end

    def worker_vars
      vars = {}
      @workers.each do |name, thread|
        #currents[thread.id] = thread.current
        vars[thread[:name]] = thread[:vars]
      end
      vars
    end

    def worker_alive? name
      @workers[name] && @workers[name].alive?
    end

  private

    def create_worker_threads n
      n.times do
        # Increment counter
        @mutex.synchronize do
          @counter +=1
        end

        # Create a dedicated thread for this worker
        name = "w#{@counter}"
        @workers[name] = create_worker_thread name
      end
    end

    def create_worker_thread name
      # @workers[name] = Thread.new name do
      Thread.new name do

        # Set thread context
        Thread.current[:name] = name
        Thread.current[:vars] = { started_at: Time.now }

        # Start working
        worker_status :starting
        loop do
          work
        end
      end
    end

    def work
      info "waiting for a job"

      # Wait for a job to come into the queue
      worker_status :waiting
      job = $queue.pop

      # Do the job
      info "processing [#{job.id}]"

      worker_status :processing, job.id
      job.wid = Thread.current[:name]
      job.process
      info "processed [#{job.id}]"
      job.wid = nil
      worker_status :done

      # Increment total processed jobs count
      $queue.counter_inc :jobs_processed

    rescue Exception => ex
        handle_job_uncaught_exception job, ex

    else
      # Clean job status
      worker_status :free
      job.wid = nil

    end

    def handle_job_uncaught_exception job, ex
      begin
        # Log the exception
        info "UNHDNALED EXCEPTION: job: #{ex.message}", lines: ex.backtrace

        # Tell the worker has creashed
        worker_status :crashed

        # Flag the job as crashed
        job.oops_after_crash ex unless job.nil?

      rescue Exception => ex
        info "DOUBLE EXCEPTION: #{ex.message}", lines: ex.backtrace

      end

      # Wait a bit
      sleep 1
    end


  protected

    def ping
    end

    def info message, context = {}
      return if @logger.nil?

      # Ensure context is a hash of options and inject context
      context = {} unless context.is_a? Hash
      context[:id] = Thread.current[:name]
      context[:origin] = self.class

      # Forward to logger
      @logger.info_with_id message, context
    end

    def worker_status status, jobid = nil
      Thread.current[:vars][:status] = status
      Thread.current[:vars][:jobid] = jobid
      Thread.current[:vars][:updted_at] = Time.now
    end

  end
end
