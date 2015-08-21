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
      worker_status WORKER_STATUS_WAITING
      #log_info "waiting"
      job = $queue.pop

      # Prepare the job for processing
      worker_status WORKER_STATUS_RUNNING, "job [#{job.id}]"
      worker_jid job.id
      job.wid = Thread.current.thread_variable_get :wid

      # Processs this job protected by a timeout
      Timeout.timeout(@timeout, RestFtpDaemon::JobTimeout) do
        job.process
      end

      # Processing done
      worker_status WORKER_STATUS_FINISHED, "job [#{job.id}]"
      worker_jid nil
      job.wid = nil

      # Increment total processed jobs count
      $queue.counter_inc :jobs_processed

    rescue RestFtpDaemon::JobTimeout => ex
      log_error "JOB TIMED OUT", ex.backtrace
      worker_status WORKER_STATUS_TIMEOUT
      worker_jid nil
      job.wid = nil

      job.oops_you_stop_now ex unless job.nil?
      sleep 1

    rescue StandardError => ex
      log_error "JOB UNHDNALED EXCEPTION: #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED
      job.oops_after_crash ex unless job.nil?
      sleep 1

    else
      # Clean job status
      job.wid = nil
    end


    if Settings.newrelic_enabled?
      add_transaction_tracer :work,       category: :task
    end

  end
end
