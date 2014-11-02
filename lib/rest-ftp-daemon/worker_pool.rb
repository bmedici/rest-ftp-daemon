module RestFtpDaemon
  class WorkerPool < RestFtpDaemon::Common

    attr_reader :requested, :processed, :wid

    def initialize(number_threads)
      # Logger
      @logger = RestFtpDaemon::Logger.new(:workers, "WORKER")

      # Check parameters
      raise "A thread count of #{number_threads} is less than one" if number_threads < 1

      # Prepare status hash
      @statuses = {}

      # Create worker threads
      info "WorkerPool initializing with #{number_threads} workers"
      @mutex = Mutex.new
      @counter = 0

      for wid in 1..number_threads
        Thread.new() do
          @mutex.synchronize do
            @counter +=1
          end
          work("w#{@counter}")
        end
      end

    end

    # def wait
    #   item = @out.pop
    #   @lock.synchronize { @processed += 1 }
    #   block_given? ? (yield item) : item
    # end

    # def progname
    #   "WORKER #{@wid}"
    # end

    def work wid
      worker_status wid, "starting"
      loop do

        begin
          info "worker [#{wid}] waiting for a job"

          # Wait for a job to come into the queue
          worker_status wid, :waiting
          job = $queue.pop
          info "worker [#{wid}] popped [#{job.id}]"

          # Do the job
          worker_status wid, :processing, job.id
          job.wid = wid
          job.process
          info "worker [#{wid}] processed [#{job.id}]"
          worker_status wid, :done

          # Increment total processed jobs count
          $queue.counter_inc :processed_jobs

        rescue Exception => ex
          worker_status wid, :crashed
          info "UNHANDLED EXCEPTION: #{ex.message}"
          ex.backtrace.each do |line|
            info line, 1
          end
          sleep 2
        else

        # Clean job status
        worker_status wid, :ready
        job.wid = nil
sleep 1

        end

      end
    end

    def get_worker_statuses
      @mutex.synchronize do
        @statuses
      end
    end

  protected

    def worker_status wid, status, jobid = nil
      @mutex.synchronize do
        @statuses[wid] ||= {}
        @statuses[wid][:status] = status
        @statuses[wid][:jobid] = jobid
        @statuses[wid][:active_at] = Time.now
      end

    end

  end
end
