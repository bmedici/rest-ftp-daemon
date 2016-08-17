# Worker used to report metrics to various services

module RestFtpDaemon
  class ReporterWorker < Worker

  protected

    def worker_init
      # Load corker conf
      config_section :reporter

      # Other configuration options
      @report_newrelic = Conf.newrelic_enabled?

      # Check that everything is OK
      return "invalid timer" unless @config[:timer].to_i > 0
      return "invalid WorkerPool" unless $pool.is_a? RestFtpDaemon::WorkerPool
      return "invalid JobQueue"   unless $queue.is_a? RestFtpDaemon::JobQueue
      return false
    end

    def worker_after
      # Sleep for a few seconds
      worker_status WORKER_STATUS_WAITING
      sleep @config[:timer]
    end

    def worker_process
      # Announce we are working
      worker_status WORKER_STATUS_REPORTING

      # Report metrics
      do_metrics
    end

  private

    def do_metrics
      # What metrics to report?
      report_newrelic = Conf.newrelic_enabled?

      # Get common metrics and dump them to logs
      log_debug "begin metrics sample"
      metrics = Metrics.sample
      log_info "collected metrics (newrelic: #{@report_newrelic})", metrics

      # Transpose metrics to NewRelic metrics
      report_newrelic(metrics) if @report_newrelic
    end

    def report_newrelic metrics
      metrics_newrelic = {}
      metrics.each do |group, pairs|
        pairs.each do |key, value|
          name = "rftpd/#{group}/#{key}"
          ::NewRelic::Agent.record_metric(name, value)
          metrics_newrelic[name] = value
        end
      end

      # Don't dump metrics unless we're debugging
      msg_newrelic = "reported metrics to NewRelic [#{ENV['NEW_RELIC_APP_NAME']}]"
      if @config[:debug]
        log_debug msg_newrelic, metrics_newrelic
      else
        log_info msg_newrelic
      end

    end

  end
end
