module RestFtpDaemon
  class Conchita

    def initialize
      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :workers

      # Conchita configuration
      @conchita = Settings.conchita
      if @conchita.nil?
        return info "conchita: missing conchita.* configuration"
      elsif @conchita[:timer].nil?
        return info "conchita: missing conchita.timer value"
      end

      # Start main loop
      info "initialized #{@conchita.inspect}"
      cleanup
    end

  protected

    def maxage status
      @conchita["clean_#{status.to_s}"] || 0
    end

    def cleanup
      loop do
        #info "cleanup"
        # info "conchita_loop: cleanup "
        $queue.expire JOB_STATUS_FINISHED,  maxage(JOB_STATUS_FINISHED)
        $queue.expire JOB_STATUS_FAILED,    maxage(JOB_STATUS_FAILED)
        $queue.expire JOB_STATUS_QUEUED,    maxage(JOB_STATUS_QUEUED)

        # Sleep for a few seconds
        sleep @conchita[:timer]
      end
    end

    # def conchita_gc
    #   # Read config state
    #   proceed = @conchita["clean_garbage"] || false
    #   #info "conchita_clean status[#{status.to_s}] \t maxage[#{maxage}] s"
    #   return unless proceed

    #   # Trig Ruby's garbage collector
    #   info "conchita_gc forced garbage collecting"
    #   GC.start
    # end

    def info message, lines = []
      return if @logger.nil?

      # Forward to logger
      @logger.info_with_id message,
        wid: :conchita,
        lines: lines,
        origin: self.class.to_s
    end

  end
end
