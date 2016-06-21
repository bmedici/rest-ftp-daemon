module RestFtpDaemon

  # Worker used to clean up the queue deleting expired jobs
  class ReporterWorker < Worker

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
      worker_status WORKER_STATUS_REPORTING

      # Report metrics
      do_metrics

    rescue StandardError => e
      log_error "CONCHITA EXCEPTION: #{e.inspect}"
      sleep 1
    else
      wait_according_to_config
    end

    def maxage status
      @config["clean_#{status}"] || 0
    end

  private

    def do_metrics
      # Prepare hash
      metrics = {}

      # Collect: jobs by status
      $queue.jobs_by_status.each do |key, value|
        metrics["jobs/#{key}"] = value
      end

      # Collect: workers by status
      workers_by_status = $pool.worker_variables.group_by(&[:status])
      workers_by_status.each do |status, workers|
        metrics["workers/#{status}"] = workers.count
      end

      # Collect: transfer rates
      $queue.rate_by(:pool).each do |key, value|
        metrics["by_pool/#{key}"] = value
      end
      $queue.rate_by(:targethost).each do |key, value|
        metrics["by_targethost/#{key}"] = value
      end

      # Collect: other
      metrics["system/jobs_count"] = $queue.jobs_count
      metrics["system/uptime"] = (Time.now - Conf.app_started).round(1)

      # Dump metrics to logs
      log_debug "metrics collected", metrics

      # NewRelic reporting
      metrics.each do |key, value|
        ::NewRelic::Agent.record_metric("rftpd/#{key}", value)
        log_debug "reported to NewRelic"
      end if Conf.newrelic_enabled?

    end

    # NewRelic instrumentation
    if Conf.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      add_transaction_tracer :work,       category: :task
    end

  end
end
