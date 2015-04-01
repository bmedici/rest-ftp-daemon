module RestFtpDaemon
  class ConchitaWorker < Worker

    def initialize wid = :conchita
      # Generic worker initialize
      super

      # Conchita configuration
      @conchita = Settings.conchita
      if @conchita.nil?
        return log_info "conchita: missing conchita.* configuration"
      elsif @conchita[:timer].nil?
        return log_info "conchita: missing conchita.timer value"
      end

      # Start main loop
      log_info "ConchitaWorker starting", @conchita
      start
    end

  protected

    def work
      worker_status :cleaning

      # Cleanup queues according to configured max-age
      $queue.expire JOB_STATUS_FINISHED,  maxage(JOB_STATUS_FINISHED)
      $queue.expire JOB_STATUS_FAILED,    maxage(JOB_STATUS_FAILED)
      $queue.expire JOB_STATUS_QUEUED,    maxage(JOB_STATUS_QUEUED)
sleep 5

      # Force garbage collector
      worker_status :collecting
      GC.start if @conchita["garbage_collector"]
sleep 5
    rescue Exception => e
      log_error "CONCHITA WORKER EXCEPTION: #{e.inspect}"
      sleep 1
    else
      # Sleep for a few seconds
      worker_status :sleeping
      sleep @conchita[:timer]
    end

    def maxage status
      @conchita["clean_#{status.to_s}"] || 0
    end

  end
end
