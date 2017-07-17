require "grape"
require "get_process_mem"

module RestFtpDaemon
  module API
    class Status < Grape::API
      include BmcDaemonLib

      ### HELPERS
      helpers do
        def log_context
          {caller: "API::Status"}
        end

        # Identify plugins
        def get_plugins
          plugins = Pluginator.find(Conf.app_name)

          pluginfo = {}
          plugins.types.each do |type, contents|
            pluginfo[type] = plugins[type]
          end

          pluginfo
        end    

          # Get counters
        def get_counters
          counters = RestFtpDaemon::Counters.instance.stats

          # Amend counters with legacy attributes
          if counters[:jobs].is_a? Hash
            counters[:jobs_finished] = counters[:jobs][:finished] || 0
            counters[:jobs_failed]   = counters[:jobs][:failed] || 0
          end
          if counters[:data].is_a? Hash
            counters[:transferred] = counters[:data][:transferred] || 0
          end

          counters
        end

      end

      ### ENDPOINTS
      desc "Show daemon status", tags: ['status']
      get "/" do
        status 200

        # Generate sutrcture
        return  {
          name: Conf.app_name,
          version: Conf.app_ver,
          started: Conf.app_started,
          hostname: `hostname`.to_s.chomp,
          jobs_count: RestFtpDaemon::JobQueue.instance.jobs_count,
          metrics: Metrics.sample,
          counters: get_counters,
          plugins: get_plugins,
          transforms: Transform::Base.available,
          workers: RestFtpDaemon::WorkerPool.instance.worker_variables,
          }

        # _types: plugins.types,
        # plugin_remotes: plugins[:remote],
        # plugin_transforms: plugins[:transform],
      end

      desc "Show status: metrics", tags: ['status']
      get "/metrics" do
        status 200
        return Metrics.sample
      end

      desc "Show status: plugins", tags: ['status']
      get "/plugins" do
        status 200
        return get_plugins
      end

      desc "Show status: counters", tags: ['status']
      get "/counters" do
        status 200
        return get_counters
      end

      desc "Show status: workers", tags: ['status']
      get "/workers" do
        status 200
        return RestFtpDaemon::WorkerPool.instance.worker_variables
      end

    end
  end
end