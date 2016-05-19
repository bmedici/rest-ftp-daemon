module RestFtpDaemon

  # Queue that stores all the Jobs waiting to be processed or fully processed
  class JobQueue
    include LoggerHelper
    attr_reader :logger

    #attr_reader :queues
    attr_reader :jobs

    if Settings.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    end

    def initialize
      # Instance variables
      @queues = {}
      @waitings = {}

      # @queue = []
      # @waiting = []

      @jobs = []

      @queues.taint          # enable tainted communication
      @waitings.taint

      taint
      @mutex = Mutex.new

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :queue

      # Identifiers generator
      @last_id = 0
      @prefix = Helpers.identifier JOB_IDENT_LEN
      log_info "JobQueue initialized (prefix: #{@prefix})"
    end

    def generate_id
      @mutex.synchronize do
        @last_id += 1
      end
      prefixed_id @last_id
    end

      def jobs_queued
      @queues
      #@queues.map { |status, jobs| jobs.size }
    end

    # Statistics on average rates
    def rate_by method_name
      # Init
      result = {}
      return unless Job.new(0, {}).respond_to? method_name

      # Select only running jobs
      @jobs.select do |job|

        job.status == JOB_STATUS_UPLOADING

      # Group them by method_name
      end.group_by do |job|

        job.send(method_name)

      # Inside each group, sum up rates
      end.map do |group, jobs|

        # Collect their rates
        rates = jobs.collect do |job|
          job.get_info :transfer, :bitrate
        end

        # And summ that up !
        # result[group] = rates.inspect
        result[group] = rates.reject(&:nil?).sum
      end

      # Return the rate
      result
    end

    # Queue infos
    def jobs_count
      @jobs.length
    end

    def jobs_by_status
      statuses = {}
      @jobs.group_by { |job| job.status }.map { |status, jobs| statuses[status] = jobs.size }
      statuses
    end
    alias jobs_count_by_status jobs_by_status

    def jobs_ids
      @jobs.collect(&:id)
    end

    def empty?
      @queue.empty?
    end

    def num_waiting
      @waiting.size
    end


    # Queue access
    def find_by_id id, prefixed = false
      # Build a prefixed id if expected
      id = prefixed_id(id) if prefixed
      log_info "find_by_id (#{id}, #{prefixed}) > #{id}"

      # Search in jobs queues
      #@jobs.reverse.find { |item| item.id == id }
      @jobs.find { |item| item.id == id }
    end

    def push job
      # Check that item responds to "priorty" method
      raise "JobQueue.push: job should respond to priority method" unless job.respond_to? :priority
      raise "JobQueue.push: job should respond to id method" unless job.respond_to? :id
      raise "JobQueue.push: job should respond to pool method" unless job.respond_to? :pool
      raise "JobQueue.push: job should respond to reset" unless job.respond_to? :reset

      @mutex.synchronize do
        # Get this job's pool @ prepare queue of this pool
        pool = job.pool
        myqueue = (@queues[pool] ||= [])

        # Store the job into the global jobs list, if not already inside
        @jobs.push(job) unless @jobs.include?(job)

        # Push job into the queue, if not already inside
        myqueue.push(job) unless myqueue.include?(job)

        # Inform the job that it's been queued / reset it
        job.reset

        # Refresh queue order
        #sort_queue!(pool)
        myqueue.sort_by!(&:weight)

        # Try to wake a worker up
        begin
          @waitings[pool] ||= []
          t = @waitings[pool].shift
          t.wakeup if t
        rescue ThreadError
          retry
        end
      end
    end
    alias <<      push
    alias enq     push
    alias requeue push

    def pop pool, non_block = false
      @mutex.synchronize do
        myqueue = (@queues[pool] ||= [])
        @waitings[pool] ||= []
        loop do
          if myqueue.empty?
            #puts "JobQueue.pop(#{pool}): empty"
            raise ThreadError, "queue empty" if non_block
            @waitings[pool].push Thread.current
            @mutex.sleep
          else
            return myqueue.pop
          end
        end
      end
    end
    alias shift pop
    alias deq pop

    def clear
      @queue.clear
    end

    # Jobs acess and searching
    def jobs_with_status status
      # No status filter: return all execept queued
      if status.empty?
        @jobs.reject { |job| job.status == JOB_STATUS_QUEUED }

      # Status filtering: only those jobs
      else
        @jobs.select { |job| job.status == status.to_s }

      end
    end

    # Jobs cleanup
    def expire status, maxage, verbose = false
# FIXME: clean both @jobs and @queue
      # Init
      return if status.nil? || maxage <= 0

      # Compute oldest limit
      time_limit = Time.now - maxage.to_i
      log_info "JobQueue.expire limit [#{time_limit}] status [#{status}]" if verbose

      @mutex.synchronize do
        # Delete jobs from the queue when they match status and age limits
        @jobs.delete_if do |job|
          # log_info "testing job [#{job.id}] updated_at [#{job.updated_at}]"

          # Skip if wrong status, updated_at invalid, or updated since time_limit
          next unless job.status == status
          next if job.updated_at.nil?
          next if job.updated_at >= time_limit

          # Ok, we have to clean it up ..
          log_info "expire [#{status}]: job [#{job.id}] updated_at [#{job.updated_at}]"

          # From any queues, remove it
          @queues.each do |pool, jobs|
            log_info "#{LOG_INDENT}unqueued from [#{pool}]" if jobs.delete(job)
          end

          # Remember we have to delete the original job !
          true
        end
      end

    end

  protected

    def prefixed_id id
      "#{@prefix}.#{id}"
    end

    if Settings.newrelic_enabled?
      add_transaction_tracer :push,                 category: :task
      add_transaction_tracer :pop,                  category: :task
      add_transaction_tracer :expire,               category: :task
      add_transaction_tracer :rate_by, category: :task
      add_transaction_tracer :jobs_count_by_status, category: :task
    end

  end
end
