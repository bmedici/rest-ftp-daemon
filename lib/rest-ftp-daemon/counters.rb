require 'singleton'

# Queue that stores all the Jobs waiting to be processed or fully processed
module RestFtpDaemon
  class Counters
    include Singleton

    def initialize
      # Initialize values
      @stats = {}

      # Create mutex
      @mutex = Mutex.new


      set :system, :started_at, Time.now
    end

    def set group, name, value
      @mutex.synchronize do
        @stats[group] ||= {}
        @stats[group][name] = value
      end
    end

    def get group, name
      @mutex.synchronize do
        @stats[group][name] if @stats[group].is_a? Hash
      end
    end

    def add group, name, value
      @mutex.synchronize do
        @stats[group] ||= {}
        @stats[group][name] ||= 0
        @stats[group][name] += value
      end
    end

    def increment group, name
      add group, name, 1
    end

    def stats
      return @stats.dup
    end

  end
end
