require "grape"
require "get_process_mem"

module RestFtpDaemon
  module API
    class Status < Grape::API

      ### ENDPOINTS
      desc "Show daemon status"
      get "/" do
        status 200

        # Check that Queue and Pool are available
        unless true
          log_error "Status API: invalid WorkerPool"
          return status 501
        end

        # Get counters
        counters = RestFtpDaemon::Counters.instance.stats

        # Amend counters with legacy attributes
        if counters[:jobs].is_a? Hash
          counters[:jobs_finished] = counters[:jobs][:finished] || 0
          counters[:jobs_failed]   = counters[:jobs][:failed] || 0
        end
        if counters[:data].is_a? Hash
          counters[:transferred] = counters[:data][:transferred] || 0
        end

        # Generate sutrcture
        return  {
          name: Conf.app_name,
          version: Conf.app_ver,
          started: Conf.app_started,
          hostname: `hostname`.to_s.chomp,
          jobs_count: RestFtpDaemon::JobQueue.instance.jobs_count,

          metrics: Metrics.sample,

          counters: counters,

          workers: $pool.worker_variables,

          }
      end

    end
  end
end
