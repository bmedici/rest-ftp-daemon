require 'thread'
require 'securerandom'

module RestFtpDaemon
  class JobQueue < Queue
    attr_reader :queued
    attr_reader :popped

    def initialize
      # Instance variables
      @queued = []
      @popped = []
      @waiting = []
      @queued.taint          # enable tainted communication
      @waiting.taint
      self.taint
      @mutex = Mutex.new

      # # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :queue

      # Identifiers generator
      @last_id = 0
      @prefix = Helpers.identifier IDENT_JOB_LEN
      info "queue initialized with prefix: #{@prefix}"

      # Mutex for counters
      @counters = {}
      @mutex_counters = Mutex.new

      # Conchita configuration
      @conchita = Settings.conchita
      if @conchita.nil?
        info "conchita: missing conchita.* configuration"
      elsif @conchita[:timer].nil?
        info "conchita: missing conchita.timer value"
      else
        Thread.new {
          begin
            conchita_loop
          rescue Exception => e
            info "CONCHITA EXCEPTION: #{e.inspect}"
          end
          }
      end

    end

    def generate_id
      rand(36**8).to_s(36)
      @last_id ||= 0
      @last_id += 1
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

    def popped_reverse_sorted_by_status status
      return [] if status.nil?

      # Select jobs from the queue if their status is (status)
      ordered_popped.reverse.select { |item| item.status == status.to_sym }
    end

    def counts_by_status
      statuses = {}
      all.group_by { |job| job.status }.map { |status, jobs| statuses[status] = jobs.size }
      statuses
    end

    def all
      @queued + @popped
    end
    def all_size
      @queued.length + @popped.length
    end

    def find_by_id id, prefixed = false
      # Build a prefixed id if expected
      id = prefixed_id(id) if prefixed
      info "find_by_id (#{id}, #{prefixed}) > #{id}"

      # Search in both queues
      @queued.select { |item| item.id == id }.last || @popped.select { |item| item.id == id }.last
    end

    def push job
      # Check that item responds to "priorty" method
      raise "JobQueue.push: job should respond to priority method" unless job.respond_to? :priority
      raise "JobQueue.push: job should respond to id method" unless job.respond_to? :id

      @mutex.synchronize do
        # Push job into the queue
        @queued.push job

        # Tell the job it's been queued
        job.set_queued if job.respond_to? :set_queued

        # Try to wake a worker up
        begin
          t = @waiting.shift
          t.wakeup if t
        rescue ThreadError
          retry
        end
      end
    end
    alias << push
    alias enq push

    def pop(non_block=false)
      # info "JobQueue.pop"
      @mutex.synchronize do
        while true
          if @queued.empty?
            # info "JobQueue.pop: empty"
            raise ThreadError, "queue empty" if non_block
            @waiting.push Thread.current
            @mutex.sleep
          else
            # info "JobQueue.pop: great, I'm not empty!!"
            return pick_one
          end
        end
      end
    end
    alias shift pop
    alias deq pop

    def empty?
      @queued.empty?
    end

    def clear
      @queued.clear
    end

    def num_waiting
      @waiting.size
    end

    def ordered_queue
      @mutex_counters.synchronize do
        @queued.sort_by { |item| [item.priority.to_i, - item.id.to_i] }
      end
    end

    def ordered_popped
      @mutex_counters.synchronize do
        @popped.sort_by { |item| [ item.wid.to_s, item.updated_at] }
        # @popped.sort_by { |item| [item.status.to_s, item.wid.to_s, item.updated_at, - item.id.to_i] }
      end
    end

  protected

    def prefixed_id id
      "#{@prefix}.#{id}"
    end

    def conchita_loop
      info "conchita starting with: #{@conchita.inspect}"
      loop do
        conchita_clean :finished
        conchita_clean :failed
        sleep @conchita[:timer]
      end
    end

    def conchita_clean status
      # Init
      return if status.nil?
      key = "clean_#{status.to_s}"

      # Read config state
      max_age = @conchita[key.to_s]
      return if [nil, false].include? max_age

      # Delete jobs from the queue if their status is (status)
      @popped.delete_if do |job|
        # Skip it if wrong status
        next unless job.status == status.to_sym

        # Skip it if updated_at invalid
        updated_at = job.updated_at
        next if updated_at.nil?

        # Skip it if not aged enough yet
        age = Time.now - updated_at
        next if age < max_age

        # Ok, we have to clean it up ..
        info "conchita_clean #{status.inspect} max_age:#{max_age} job:#{job.id} age:#{age}"
        true
      end

    end

    def pick_one  # called inside a mutex/sync
      # Sort jobs by priority and get the biggest one
      picked = ordered_queue.last
      return nil if picked.nil?

      # Move it away from the queue to the @popped array
      @queued.delete_if { |item| item == picked }
      @popped.push picked

      # Return picked
      #info "JobQueue.pick_one: #{picked.id}"
      picked
    end

  private

    def info message
      return if @logger.nil?
      @logger.info_with_id message
    end

  end
end
