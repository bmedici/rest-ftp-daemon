module RestFtpDaemon

  class Common

  protected

    # FIXME: should be moved to class itself to get rid of this parent class

    def info message, level = 0
      @logger.info(message, level) unless @logger.nil?
    end

  end
end
