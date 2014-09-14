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
