# Worker used to clean up the queue deleting expired jobs

module RestFtpDaemon
  class ConchitaWorker < Worker

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
      $queue.expire JOB_STATUS_FINISHED,  maxage(JOB_STATUS_FINISHED),  @config[:debug]
      $queue.expire JOB_STATUS_FAILED,    maxage(JOB_STATUS_FAILED),    @config[:debug]
      $queue.expire JOB_STATUS_QUEUED,    maxage(JOB_STATUS_QUEUED),    @config[:debug]

      # Force garbage collector
      GC.start if @config["garbage_collector"]
    end

  private

    def maxage status
      @config["clean_#{status}"] || 0
    end

  end
end
