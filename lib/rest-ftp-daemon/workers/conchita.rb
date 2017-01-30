# Worker used to clean up the queue deleting expired jobs

module RestFtpDaemon
  class ConchitaWorker < Worker

  protected

    def worker_init
      # Load corker conf
      config_section :conchita

      # Check that everything is OK
      return "conchita disabled" if disabled?(@config[:timer])
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
      RestFtpDaemon::JobQueue.instance.expire STATUS_FINISHED,  maxage(STATUS_FINISHED),  @config[:debug]
      RestFtpDaemon::JobQueue.instance.expire STATUS_FAILED,    maxage(STATUS_FAILED),    @config[:debug]
      RestFtpDaemon::JobQueue.instance.expire STATUS_QUEUED,    maxage(STATUS_QUEUED),    @config[:debug]

      # Force garbage collector
      GC.start if @config["garbage_collector"]
    end

  private

    def maxage status
      @config["clean_#{status}"] || 0
    end

  end
end