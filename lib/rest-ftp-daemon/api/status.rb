module RestFtpDaemon
  module API
    class Root < Grape::API


####### GET /status

      # Server global status
      get '/status' do
        log_info 'GET /status'
        mem = GetProcessMem.new

        status 200
        return  {
          hostname: `hostname`.chomp,
          version: APP_VER,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          counters: $queue.counters,
          memory_bytes: mem.bytes.to_i,
          memory_mb: mem.mb.round(0),
          status: $queue.counts_by_status,
          workers: $pool.worker_variables,
          jobs_count: $queue.jobs_count,
          jobs_queued: $queue.queued_ids,
          config: Helpers.get_censored_config,
          #routes: RestFtpDaemon::API::Root::routes,
          }
      end

    end
  end
end
