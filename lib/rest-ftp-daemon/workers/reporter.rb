# Worker used to report metrics to various services

module RestFtpDaemon
  class ReporterWorker < Worker

  protected

    def worker_init
      # Load corker conf
      config_section :reporter

      # Other configuration options
      @feature_newrelic = Conf.feature_newrelic?

      # Check that everything is OK
      return "reporter disabled"  if disabled?(@config[:timer])
      return "invalid timer"      unless @config[:timer].to_i > 0
      return false
    end

    def worker_process
      # Announce we are working
      worker_status Worker::STATUS_WORKING

      # Report metrics
      do_metrics
    end

  private

    def do_metrics
      # Get common metrics and dump them to logs
      log_debug "begin metrics sample"
      metrics = Metrics.sample

      # Skip following if no valid metrics collected
      unless metrics.is_a? Hash
        log_error "unable to collect metrics"
        return
      end
      log_info "collected metrics (newrelic: #{@feature_newrelic.inspect})", metrics

      # Transpose metrics to NewRelic metrics
      report_newrelic(metrics) if @feature_newrelic
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
      newrelic_app_name = Conf.at(:newrelic, :app_name)
      msg_newrelic = "reported metrics to NewRelic [#{newrelic_app_name}]"
      if @config[:debug]
        log_debug msg_newrelic, metrics_newrelic
      else
        log_info msg_newrelic
      end

    end

  end
end