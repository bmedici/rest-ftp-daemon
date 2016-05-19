require "get_process_mem"

module RestFtpDaemon
  module API
    class Status < Grape::API

      desc "Show daemon status"
      get "/" do
        mem = GetProcessMem.new
        status 200
        return  {
          hostname: `hostname`.to_s.chomp,
          version: APP_VER,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          counters: $queue.counters,
          memory_bytes: mem.bytes.to_i,
          memory_mb: mem.mb.round(0),


          jobs_count: $queue.jobs_count,
          status: $queue.jobs_count_by_status,

          # jobs_finished: $queue.jobs_finished,
          #rate_by_pool1: $queue.rate_by_pool,
          rate_by_pool: $queue.rate_by(:pool),
          rate_by_targethost: $queue.rate_by(:targethost),
          jobs_by_status: $queue.jobs_by_status,

          #rates_per_host: $queue.rates_per_host,

          workers: $pool.worker_variables,
          #kpis: $queue.queued_ids,
          }
      end

    end
  end
end
