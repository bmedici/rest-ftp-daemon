# Worker used to process Jobs

module RestFtpDaemon
  class TransferWorker < Worker

  protected

    def worker_init
      # Load standard config
      config_section    :transfer
      @endpoints        = Conf[:endpoints]

      # Timeout and retry config
      return "invalid timeout" unless @config[:timeout].to_i > 0

      # Log that
      log_info "JobWorker worker_init", {
        pool: @pool,
        timeout: @config[:timeout]
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
      job = RestFtpDaemon::JobQueue.instance.pop @pool

      # Work on this job
      work_on_job job

      # Clean job status
      job.wid = nil
      #sleep 1

      # Handle the retry if needed
      handle_job_result job
    end

    def work_on_job job
      # Prepare job and worker for processing
      worker_jid job.id
      worker_status WORKER_STATUS_RUNNING, job
      job.wid = Thread.current.thread_variable_get :wid

      # Processs this job protected by a timeout
      Timeout.timeout(@config[:timeout], RestFtpDaemon::JobTimeout) do
        job.process
      end

      # Increment total processed jobs count
      RestFtpDaemon::Counters.instance.increment :jobs, :processed

    rescue RestFtpDaemon::JobTimeout => ex
      log_error "JOB TIMEOUT", ex.backtrace
      worker_status WORKER_STATUS_TIMEOUT, job

      # Inform the job
      job.oops_you_stop_now ex unless job.nil?

    rescue RestFtpDaemon::AssertionFailed, RestFtpDaemon::AttributeMissing, StandardError => ex
      log_error "JOB EXCEPTION ex[#{ex.class}] #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED

      # Inform the job
      job.oops_after_crash ex unless job.nil?
    end

    def handle_job_result job
      # If job status requires a retry, just restack it
      if !job.error
        # Processing successful
        log_error "job finished with no error"
        worker_status WORKER_STATUS_FINISHED, job

      elsif error_not_eligible(job)
        log_error "not retrying [#{job.error}] retry_on not eligible"

      elsif error_reached_for(job)
        log_error "not retrying [#{job.error}] retry_for reached [#{@config[:retry_for]}s]"

      elsif error_reached_max(job)
        log_error "not retrying [#{job.error}] retry_max reached #{tentatives(job)}"

      else
        # Delay cannot be negative, and will be 1s minimum
        retry_after = [@config[:retry_after] || DEFAULT_RETRY_AFTER, 1].max
        log_info "retry job [#{job.id}] in [#{retry_after}s] tried #{tentatives(job)}"

        # Wait !
        worker_status WORKER_STATUS_RETRYING, job
        sleep retry_after
        log_debug "job [#{job.id}] requeued after [#{retry_after}s] delay"

        # Now, requeue this job
        RestFtpDaemon::JobQueue.instance.requeue job
      end
    end

    def error_not_eligible job
      # No, if no eligible errors
      return true unless @config[:retry_on].is_a?(Enumerable)

      # Tell if this error is in the list
      return !@config[:retry_on].include?(job.error.to_s)
    end

    def error_reached_for job
      # Not above, if no limit definded
      return false unless @config[:retry_for]

      # Job age above this limit
      return job.age >= @config[:retry_for]
    end

    def error_reached_max job
      # Not above, if no limit definded
      return false unless @config[:retry_max]

      # Job age above this limit
      return job.tentatives >= @config[:retry_max]
    end

    def tentatives job
      "[#{job.tentatives}/#{@config[:retry_max]}]"
    end

  end
end
