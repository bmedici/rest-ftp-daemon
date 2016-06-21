module RestFtpDaemon

  # Worker used to clean up the queue deleting expired jobs
  class ConchitaWorker < Worker

    def initialize wid, pool = nil
      # Call dady and load my conf
      super

      # Start main loop
      log_info "#{self.class.name} starting", @config
      start
    end

  protected

    # def log_prefix
    #  [
    #   Thread.current.thread_variable_get(:wid),
    #   nil,
    #   nil
    #   ]
    # end

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
      wait_according_to_config
    end

    def maxage status
      @conchita["clean_#{status}"] || 0
    end

  private

    # NewRelic instrumentation
    if Conf.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :work,       category: :task
    end

  end
end
