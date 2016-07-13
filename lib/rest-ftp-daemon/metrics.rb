module RestFtpDaemon
  class Metrics

    def self.sample
      # Check validity of globals
      return log_error "Metrics.sample: invalid WorkerPool" unless $pool.is_a? RestFtpDaemon::WorkerPool
      return log_error "Metrics.sample: invalid JobQueue"  unless $queue.is_a? RestFtpDaemon::JobQueue

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

        # Check validity of globals
        unless $pool.is_a? RestFtpDaemon::WorkerPool
          log_error "Metrics.workers_count_by_status: invalid WorkerPool"
          return counts
        end

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
