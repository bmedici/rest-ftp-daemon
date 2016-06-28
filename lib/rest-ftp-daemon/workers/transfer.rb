module RestFtpDaemon

  # Worker used to process Jobs
  class TransferWorker < Shared::WorkerBase

  protected

    def worker_init
      # Load standard config
      config_section :transfer
      @timeout          = @config[:timeout]

      # Timeout and retry config
      return "invalid timeout" unless @config[:timeout].to_i > 0

      # Retry config
      @retry_on_errors  = @config[:retry_on]
      @retry_max_age    = @config[:retry_for]
      @retry_max_runs   = @config[:retry_max]
      @retry_delay      = @config[:retry_after]

      # Log that
      log_info "JobWorker worker_init", {
        pool: @pool,
        timeout: @timeout
      }

      return false
    end

    def worker_after
      # Clean worker status
      worker_jid nil
    end

  private

    def worker_process
      # Wait for a job to be available in the queue
      worker_status WORKER_STATUS_WAITING
      job = $queue.pop @pool

      # Work on this job
      work_on_job(job)

      # Clean job status
      job.wid = nil
      #sleep 1

      # If job status requires a retry, just restack it
      if !job.error
        #log_info "job succeeded"

      elsif !(@retry_on_errors.is_a?(Enumerable) && @retry_on_errors.include?(job.error))
        log_error "not retrying: error not eligible"

      elsif @retry_max_age && (job.age >= @retry_max_age)
        log_error "not retrying: max_age reached (#{@retry_max_age} s)"

      elsif @retry_max_runs && (job.runs >= @retry_max_runs)
        log_error "not retrying: max_runs reached (#{@retry_max_runs} tries)"

      else
        # Delay cannot be negative, and will be 1s minimum
        retry_after = [@retry_delay || DEFAULT_RETRY_DELAY, 1].max
        log_info "retrying job: waiting for #{retry_after} seconds"

        # Wait !
        sleep retry_after
        log_info "retrying job: requeued after delay"

        # Now, requeue this job
        $queue.requeue job
      end

    rescue StandardError => ex
      log_error "WORKER UNHANDLED EXCEPTION: #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED
    end

    def work_on_job job
      # Prepare job and worker for processing
      worker_jid job.id
      worker_status WORKER_STATUS_RUNNING, job
      job.wid = Thread.current.thread_variable_get :wid

      # Prepare job config
      job.endpoints = @config[:endpoints] rescue {})
      job.config = @config[:config] rescue {})

      # Processs this job protected by a timeout
      Timeout.timeout(@timeout, RestFtpDaemon::JobTimeout) do
        job.process
      end

      # Processing done
      worker_status WORKER_STATUS_FINISHED, job

      # Increment total processed jobs count
      $counters.increment :jobs, :processed

    rescue RestFtpDaemon::JobTimeout => ex
      log_error "JOB TIMED OUT", ex.backtrace
      worker_status WORKER_STATUS_TIMEOUT

      # Inform the job
      job.oops_you_stop_now ex unless job.nil?

    rescue StandardError => ex
      log_error "JOB UNHANDLED EXCEPTION ex[#{ex.class}] #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED

      # Inform the job
      job.oops_after_crash ex unless job.nil?
    end

  end
end
