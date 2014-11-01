module RestFtpDaemon

  class Common

  protected


    def info message, level = 0
      @logger.info(message, level) unless @logger.nil?
    end

  end
end
