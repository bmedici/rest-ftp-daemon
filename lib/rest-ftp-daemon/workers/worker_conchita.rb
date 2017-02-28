# Worker used to clean up the queue deleting expired jobs

module RestFtpDaemon
  class WorkerConchita < Worker

  protected

    def worker_init
      # Load corker conf
      config_section :conchita

      # Check that everything is OK
      return "conchita disabled" if disabled?(@config[:timer])
      return "invalid timer" unless @config[:timer].to_i > 0
      return false
    end

    def worker_process
      # Announce we are working
      worker_status Worker::STATUS_WORKING

      # Cleanup queues according to configured max-age
      RestFtpDaemon::JobQueue.instance.expire Job::STATUS_FINISHED,  maxage(Job::STATUS_FINISHED),  @config[:debug]
      RestFtpDaemon::JobQueue.instance.expire Job::STATUS_FAILED,    maxage(Job::STATUS_FAILED),    @config[:debug]
      RestFtpDaemon::JobQueue.instance.expire Job::STATUS_QUEUED,    maxage(Job::STATUS_QUEUED),    @config[:debug]

      # Force garbage collector
      GC.start if @config["garbage_collector"]
    end

  private

    def maxage status
      @config["clean_#{status}"] || 0
    end

  end
end
