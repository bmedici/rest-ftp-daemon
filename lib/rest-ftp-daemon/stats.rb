module RestFtpDaemon

  # Queue that stores all the Jobs waiting to be processed or fully processed
  class Stats
    attr_reader :stats

    if Settings.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    end

    def initialize
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
