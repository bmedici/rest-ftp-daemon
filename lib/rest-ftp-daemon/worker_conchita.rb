module RestFtpDaemon
  class ConchitaWorker < Worker

    def initialize wid = :conchita
      # Generic worker initialize
      super

      # Use debug ?
      @debug = (Settings.at :debug, :conchita) == true
      @log_worker_status_changes = @debug

      # Conchita configuration
      @conchita = Settings.conchita
      if !@conchita.is_a? Hash
        return log_info "ConchitaWorker: missing conchita.* configuration"
      elsif @conchita[:timer].nil?
        return log_info "ConchitaWorker: missing conchita.timer value"
      end

      # Start main loop
      log_info "ConchitaWorker starting", @conchita
      start
    end

  protected

    def work
      # Announce we are working
      worker_status WORKER_STATUS_CLEANING

      # Cleanup queues according to configured max-age
      $queue.expire JOB_STATUS_FINISHED,  maxage(JOB_STATUS_FINISHED),  @debug
      $queue.expire JOB_STATUS_FAILED,    maxage(JOB_STATUS_FAILED),    @debug
      $queue.expire JOB_STATUS_QUEUED,    maxage(JOB_STATUS_QUEUED),    @debug

      # Force garbage collector
      GC.start if @conchita["garbage_collector"]

    rescue StandardError => e
      log_error "CONCHITA EXCEPTION: #{e.inspect}"
      sleep 1
    else
      # Restore previous status
      worker_status WORKER_STATUS_WAITING

      # Sleep for a few seconds
      sleep @conchita[:timer]
    end

    def maxage status
      @conchita["clean_#{status}"] || 0
    end


    if Settings.newrelic_enabled?
      add_transaction_tracer :work,       category: :task
    end

  end
end
