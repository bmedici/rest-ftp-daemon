module RestFtpDaemon
  class Worker
    include LoggerHelper
    attr_reader :logger

    if Settings.newrelic_enabled?
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
    end

    def initialize wid
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers

      # Worker name
      @wid = wid

      # Set thread context
      Thread.current.thread_variable_set :wid, wid
      Thread.current.thread_variable_set :started_at, Time.now
      worker_status :starting
    end

  protected

    def log_context
      {
      wid: @wid,
      tag_1_worker_object: true
      }
    end

    def start
      loop do
        begin
          work
        rescue Exception => e
          log_error "WORKER EXCEPTION: #{e.inspect}"
          sleep 1
        end
      end
    end

    def worker_status status
      Thread.current.thread_variable_set :status, status
      Thread.current.thread_variable_set :updted_at, Time.now
    end

    def worker_jid jid
      Thread.current.thread_variable_set :jid, jid
      Thread.current.thread_variable_set :updted_at, Time.now
    end

    if Settings.newrelic_enabled?
      add_transaction_tracer :work, :category => :task
    end

  end
end
