module RestFtpDaemon
  class WorkerPool < RestFtpDaemon::Common

    attr_reader :requested, :processed

    def initialize(number_threads)
      # Call super
      super()

      # Check parameters
      raise "A thread count of #{number_threads} is less than one" if number_threads < 1
      @wid = "-"


      # Create worker threads
      info "WorkerPool initializing with #{number_threads} workers"
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

    def run
      # Generate a random key
      @wid = SecureRandom.hex(2)

      begin
        loop do
          info "worker [#{@wid}] ready, waiting for a job"

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
