module RestFtpDaemon
  class WorkerPool

    attr_reader :wid

    def initialize number_threads
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers

      # Check parameters
      raise "A thread count of #{number_threads} is less than one" if number_threads < 1

      # Prepare status hash
      @statuses = {}
      @workers = {}

      # Create worker threads
      info "WorkerPool initializing with #{number_threads} workers"
      @mutex = Mutex.new
      @counter = 0

      number_threads.times do
        # Increment counter
        @mutex.synchronize do
          @counter +=1
        end
        name = "w#{@counter}"

        th = Thread.new name do

          # Set thread context
          Thread.current[:name] = name
          Thread.current[:vars] = {
            started_at: Time.now,
            }

          # Start working
          work
        end

        # Add this worker to the ThreadGroup
        @workers[name] = th
      end

    end

    def work
      worker_status :starting

      loop do

        begin
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
          worker_status :crashed
          info "UNHANDLED EXCEPTION: #{ex.message}"
          ex.backtrace.each do |line|
            info line, 1
          end
          sleep 1

        else
          # Clean job status
          worker_status :free
          job.wid = nil

        end

      end
    end

    def worker_vars
      vars = {}

      @workers.each do |name, thread|
        #currents[thread.id] = thread.current
        vars[thread[:name]] = thread[:vars]
      end

      vars
    end

  protected

    def ping
    end

    def info message, context = {}
      return if @logger.nil?

      # Inject context
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
