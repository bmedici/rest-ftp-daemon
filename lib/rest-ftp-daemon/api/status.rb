module RestFtpDaemon
  module API
    class Root < Grape::API


####### GET /status

      # Server global status
      get '/status' do
        info "GET /status"
        status 200
        return  {
          hostname: `hostname`.chomp,
          version: APP_VER,
          config: Helpers.get_censored_config,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          counters: $queue.counters,
          status: $queue.counts_by_status,
          workers: $pool.worker_variables,
          jobs_count: $queue.jobs_count,
          jobs_queued: $queue.queued_ids
          #routes: RestFtpDaemon::API::Root::routes,
          }
      end

    end
  end
end
