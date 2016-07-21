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
      job = $queue.pop @pool

      # Work on this job
      work_on_job(job)

      # Clean job status
      job.wid = nil
      #sleep 1

      # If job status requires a retry, just restack it
      if !job.error
        #log_info "job succeeded"

      elsif !(@config[:retry_on].is_a?(Enumerable) && @config[:retry_on].include?(job.error))
        log_error "not retrying: error not eligible"

      elsif @config[:retry_for] && (job.age >= @config[:retry_for])
        log_error "not retrying: max_age reached (#{@config[:retry_for]} s)"

      elsif @config[:retry_max] && (job.runs >= @config[:retry_max])
        log_error "not retrying: max_runs reached (#{@config[:retry_max]} tries)"

      else
        # Delay cannot be negative, and will be 1s minimum
        retry_after = [@config[:retry_after] || DEFAULT_RETRY_AFTER, 1].max
        log_info "retrying job: waiting for #{retry_after} seconds"

        # Wait !
        sleep retry_after
        log_info "retrying job: requeued after delay"

        # Now, requeue this job
        $queue.requeue job
      end
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

    # NewRelic instrumentation
    add_transaction_tracer :worker_init,       category: :task
    add_transaction_tracer :worker_after,      category: :task
    add_transaction_tracer :worker_process,    category: :task

  end
end
