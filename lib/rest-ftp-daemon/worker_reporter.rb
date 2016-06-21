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
      log_error "EXCEPTION: #{e.inspect}"
      sleep 1
    else
      wait_according_to_config
    end

    def maxage status
      @config["clean_#{status}"] || 0
    end

  private

    def do_metrics
      # Prepare context
      metrics = {}
      mem = GetProcessMem.new

      # Collect: jobs by status
      $queue.jobs_by_status.each do |key, value|
        metrics["jobs_by_status/#{key}"] = value
      end

      # Collect: workers by status
      $pool.worker_variables.group_by do |wid, vars|
        vars[:status]
      end.each do |status, workers|
        metrics["workers_by_status/#{status}"] = workers.count
      end

      # Collect: transfer rates
      $queue.rate_by(:pool).each do |key, value|
        metrics["rate_by_pool/#{key}"] = value
      end
      $queue.rate_by(:targethost).each do |key, value|
        metrics["rate_by_targethost/#{key}"] = value
      end

      # Collect: other
      metrics["system/jobs_count"] = $queue.jobs_count
      metrics["system/uptime"] = (Time.now - Conf.app_started).round(1)
      metrics["system/memory"] = mem.bytes.to_i
      metrics["system/threads"] = Thread.list.count

      # Dump metrics to logs
      log_debug "metrics collected", metrics

      # NewRelic reporting
      if Conf.newrelic_enabled?
        metrics.each do |key, value|
          ::NewRelic::Agent.record_metric("rftpd/#{key}", value)
        end
        log_debug "reported [#{metrics.size}] metrics to NewRelic"
      end

    end

  end
end
