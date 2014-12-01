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
          jobs_count: $queue.all_size,
          jobs_queued: $queue.queued.collect(&:id),
          jobs_popped: $queue.popped.collect(&:id),
          #routes: RestFtpDaemon::API::Root::routes,
          }
      end

    end
  end
end
