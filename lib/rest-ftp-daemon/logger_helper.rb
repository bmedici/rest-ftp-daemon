module RestFtpDaemon
  module LoggerHelper

  protected

    def log_info message, lines = []
      logger.info_with_id message, log_context.merge({
        from: self.class.to_s,
        lines: lines,
        level: Logger::INFO
        })
    end

    def log_error message, lines = []
      logger.info_with_id message, log_context.merge({
        from: self.class.to_s,
        lines: lines,
        level: Logger::ERROR
        })
    end

    def log_context
      {}
    end
  end
end
