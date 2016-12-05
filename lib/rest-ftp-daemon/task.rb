module RestFtpDaemon
  class Task
    # include Singleton
    include BmcDaemonLib::LoggerHelper
    def initialize name, jid = nil, wid = nil
      @name = name
      @jid = jid
      @wid = wid

      # Logger # FIXME: should be :jobs
      log_pipe      :workflow
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