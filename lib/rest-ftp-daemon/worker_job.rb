module RestFtpDaemon
  class JobWorker < Worker

    def initialize wid
      # Generic worker initialize
      super

      # Timeout config
      @timeout = (Settings.transfer.timeout rescue nil) || DEFAULT_WORKER_TIMEOUT

      # Start main loop
      log_info "JobWorker starting", ["timeout: #{@timeout}"]
      start
    end

  protected

    def work
      # Wait for a job to come into the queue
      worker_status :waiting
      log_info "waiting for a job"
      job = $queue.pop

      # Prepare the job for processing
      worker_status :working
      worker_jid job.id
      log_info "working with job [#{job.id}]"
      job.wid = Thread.current.thread_variable_get :wid

      # Processs this job protected by a timeout
      Timeout::timeout(@timeout, RestFtpDaemon::JobTimeout) do
        job.process
      end

      # Processing done
      worker_status :finished
      log_info "finished with job [#{job.id}]"
      worker_jid nil
      job.wid = nil

      # Increment total processed jobs count
      $queue.counter_inc :jobs_processed

    rescue RestFtpDaemon::JobTimeout => ex
      log_error "JOB TIMED OUT", lines: ex.backtrace
      worker_status :timeout
      job.oops_you_stop_now ex unless job.nil?
      sleep 1

    rescue Exception => ex
      log_error "JOB UNHDNALED EXCEPTION: #{ex.message}", lines: ex.backtrace
      worker_status :crashed
      job.oops_after_crash ex unless job.nil?
      sleep 1

    else
      # Clean job status
      worker_status :free
      job.wid = nil

    end

  end
end
