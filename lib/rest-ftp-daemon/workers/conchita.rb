module RestFtpDaemon

  # Worker used to clean up the queue deleting expired jobs
  class ConchitaWorker < Shared::WorkerBase

  protected

    def worker_init
      # Load corker conf
      config_section :conchita

      # Check that everything is OK
      return "invalid timer" unless @config[:timer].to_i > 0
      return false
    end

    def worker_after
      # Sleep for a few seconds
      worker_status WORKER_STATUS_WAITING
      sleep @config[:timer]
    end

    def worker_process
      # Announce we are working
      worker_status WORKER_STATUS_CLEANING

      # Cleanup queues according to configured max-age
      $queue.expire JOB_STATUS_FINISHED,  maxage(JOB_STATUS_FINISHED),  @debug
      $queue.expire JOB_STATUS_FAILED,    maxage(JOB_STATUS_FAILED),    @debug
      $queue.expire JOB_STATUS_QUEUED,    maxage(JOB_STATUS_QUEUED),    @debug

      # Force garbage collector
      GC.start if @config["garbage_collector"]

    rescue StandardError => e
      log_error "EXCEPTION: #{e.inspect}"
      sleep 1
    end

  private

    def maxage status
      @config["clean_#{status}"] || 0
    end

  end
end
