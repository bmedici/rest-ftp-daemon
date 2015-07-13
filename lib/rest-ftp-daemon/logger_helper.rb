require "logger"

module RestFtpDaemon
  module LoggerHelper

  protected

    def log_info message, lines = []
      log message, lines, Logger::INFO
    end

    def log_error message, lines = []
      log message, lines, Logger::ERROR
    end

    def log_debug message, lines = []
      log message, lines, Logger::DEBUG
    end

    def log_context
      {}
    end

  private

    def log message, lines, level
      context = log_context || {}
      logger.info_with_id message, context.merge({
        from: self.class.to_s,
        lines: lines,
        level: level
        })
    end

  end
end
