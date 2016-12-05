module RestFtpDaemon
  class Task
    include BmcDaemonLib::LoggerHelper

    # Class options
    attr_reader :jobs
    attr_reader :name
    attr_accessor :inputs
    attr_accessor :outputs

    def initialize name, jid = nil, wid = nil
      # Init context
      @inputs = []
      @outputs = []
      @name = name
      @jid = jid
      @wid = wid

      log_pipe      :workflow
    end

    def do_before
      log_debug "inputs", @inputs.map(&:path)
    end

    def work
    end

    def do_after
      log_debug "outputs", @outputs.map(&:path)
    end

  private

    def log_context
      {
        wid: @wid,
        jid: @jid,
        id: name
      }
    end

  end
end