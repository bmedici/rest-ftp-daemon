module RestFtpDaemon
  class WorkerPool < RestFtpDaemon::Common

    attr_reader :requested, :processed

    def initialize(number_threads)
      # Check parameters
      raise "A thread count of #{number_threads} is less than one" if number_threads < 1
      @wid = "-"

      # Call super
      super()

      # Create worker threads
      number_threads.times do
        Thread.new { run }
      end
    end

    def wait
      item = @out.pop
      @lock.synchronize { @processed += 1 }
      block_given? ? (yield item) : item
    end

    def progname
      "WORKER #{@wid}"
    end
    #     progname = "Job [#{id}]" unless id.nil?
    # progname = "Worker [#{id}]" unless worker_id.nil?

    def run
      # Generate a random key
      @wid = SecureRandom.hex(2)

      begin
        loop do
          info "worker [#{@wid}] waiting for a job... "

          # Wait for a job to come into the queue
          job = $queue.pop
          prefix = "working on job [#{job.id}]"

          # Do the job
          info "job [#{job.id}] processing: #{job.inspect}"
          job.process

        end
      rescue Exception => ex
        info 'WORKER UNHANDLED EXCEPTION: ', ex.message , "\n", ex.backtrace.join("\n")
      end
    end

    def process job

      @lock.synchronize do
        job.dummy
      end

    end

  end
end
