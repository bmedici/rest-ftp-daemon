module RestFtpDaemon
  class Metrics

    def self.sample
      # Prepare external deps
      mem = GetProcessMem.new

      # Build final value
      return  {
        system: {
          uptime:           (Time.now - Conf.app_started).round(1),
          memory:           mem.bytes.to_i,
          threads:          Thread.list.count,
          },
        jobs_by_status:     $queue.jobs_by_status,
        rate_by_pool:       $queue.rate_by(:pool),
        rate_by_targethost: $queue.rate_by(:targethost),
        queued_by_pool:     $queue.queued_by_pool,
        workers_by_status:  self.workers_count_by_status,
        }
    end

    private

      # Collect: workers by status
      def self.workers_count_by_status
        # Init
        counts = {}

        $pool.worker_variables.group_by do |wid, vars|
          vars[:status]
        end.each do |status, workers|
          counts[status] = workers.count
        end

        # Return count
        counts
      end

  end
end
