# Queue that stores all the Jobs waiting to be processed or fully processed
require 'singleton'

module RestFtpDaemon
  class Counters
    attr_reader :stats
    include Singleton

    def initialize
      # Initialize values
      @stats = {}
      @mutex_stats = Mutex.new
    end

    def set group, name, value
      @mutex_stats.synchronize do
        @stats[group] ||= {}
        @stats[group][name] = value
      end
    end

    def get group, name
      @mutex_stats.synchronize do
        @stats[group][name] if @stats[group].is_a? Hash
      end
    end

    def add group, name, value
      @mutex_stats.synchronize do
        @stats[group] ||= {}
        @stats[group][name] ||= 0
        @stats[group][name] += value
      end
    end

    def increment group, name
      add group, name, 1
    end

  end
end
