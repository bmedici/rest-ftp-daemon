require 'thread'

module RestFtpDaemon
  class JobQueue < Queue

    def initialize
      @queued = []
      @popped = []

      @waiting = []
      @queued.taint          # enable tainted communication
      @waiting.taint
      self.taint
      @mutex = Mutex.new
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

    def queued
      @queued
    end
    def queued_size
      @queued.length
    end

    def popped
      @popped
    end
    def popped_size
      @popped.length
    end

    def all
      @queued + @popped
    end
    def all_size
      popped_size + queued_size
    end

    def push(obj)
      # Check that itme responds to "priorty" method
      raise "object should respond to priority method" unless obj.respond_to? :priority

      @mutex.synchronize{
        @queued.push obj
        begin
          t = @waiting.shift
          t.wakeup if t
        rescue ThreadError
          retry
        end
      }
    end
    alias << push
    alias enq push

    #
    # Retrieves data from the queue.  If the queue is empty, the calling thread is
    # suspended until data is pushed onto the queue.  If +non_block+ is true, the
    # thread isn't suspended, and an exception is raised.
    #
    def pop(non_block=false)
      @mutex.synchronize{
        while true
          if @queued.empty?
            raise ThreadError, "queue empty" if non_block
            @waiting.push Thread.current
            @mutex.sleep
          else
            return pick
          end
        end
      }
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

  protected

    def pick
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
      max_age = @conchita[key]
      return if [nil, false].include? max_age

      # Delete jobs from the queue if their status is (status)
      @popped.delete_if do |job|
        # Skip it if wrong status
        next unless job.get(:status) == status.to_sym

        # Skip it if updated_at invalid
        updated_at = job.get(:updated_at)
        next if updated_at.nil?

        # Skip it if not aged enough yet
        age = Time.now - updated_at
        next if age < max_age

        # Ok, we have to clean it up ..
        info "conchita_clean #{status.to_s} max_age:#{max_age} job:#{job.id} age:#{age}"
        true
      end

    end
      # Sort jobs by priority and get the biggest one
      picked = @queued.sort { |a,b| a.priority.to_i <=> b.priority.to_i }.last

      # Delete it from the queue
      @queued.delete_if { |item| item == picked } unless picked.nil?

      # Stack it to popped items
      @popped.push picked

      # Return picked
      picked
    end

  end
end
