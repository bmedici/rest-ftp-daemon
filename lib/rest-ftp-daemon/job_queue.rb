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

      # Mutex for counters
      @counters = {}
      @mutex_counters = Mutex.new
    end

    def generate_id
      @mutex.synchronize do
        @last_id += 1
      end
      prefixed_id @last_id
    end

    def counter_add name, value
      @mutex_counters.synchronize do
        @counters[name] ||= 0
        @counters[name] += value
      end
    end

    def counter_inc name
      counter_add name, 1
    end

    def counter_get name
      @mutex_counters.synchronize do
        @counters[name]
      end
    end

    def counters
      @mutex_counters.synchronize do
        @counters
      end
    end

    def jobs_queued
      @queues
    end

    def jobs_with_status status
      # No status filter: return all execept queued
      if status.empty?
        @jobs.reject { |job| job.status == JOB_STATUS_QUEUED }

      # Status filtering: only those jobs
      else
        @jobs.select { |job| job.status.to_s == status.to_s }

      end
    end

    def counts_by_status
      statuses = {}
      @jobs.group_by { |job| job.status }.map { |status, jobs| statuses[status] = jobs.size }
      statuses
    end

    def jobs_count
      @jobs.length
    end

    def queued_ids
      @queues.collect{|pool, jobs| jobs.collect(&:id)}
    end

    def jobs_ids
      @jobs.collect(&:id)
    end

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

    def empty?
      @queue.empty?
    end

    def clear
      @queue.clear
    end

    def num_waiting
      @waiting.size
    end

    def expire status, maxage, verbose = false
# FIXME: clean both @jobs and @queue
      # Init
      return if status.nil? || maxage <= 0

      # Compute oldest possible birthday
      before = Time.now - maxage.to_i

      # Verbose output ?
      log_info "JobQueue.expire \t[#{status}] \tbefore \t[#{before}]" if verbose

      @mutex.synchronize do
        # Delete jobs from the queue when they match status and age limits
        @jobs.delete_if do |job|

          # Skip if wrong status, updated_at invalid, or too young
          next unless job.status == status
          next if job.updated_at.nil?
          next if job.updated_at > before

          # Ok, we have to clean it up ..
          log_info "expire [#{status}] [#{maxage}] > [#{job.id}] [#{job.updated_at}]"
          log_info "#{LOG_INDENT}unqueued" if @queue.delete(job)

          true
        end
      end

    end

  protected

    def prefixed_id id
      "#{@prefix}.#{id}"
    end

    if Settings.newrelic_enabled?
      add_transaction_tracer :push,             category: :task
      add_transaction_tracer :pop,              category: :task
      add_transaction_tracer :expire,           category: :task
      add_transaction_tracer :counts_by_status, category: :task
    end

  end
end
