module RestFtpDaemon
  class TaskImport < Task
    def do_before
      super

      # Check source
      raise RestFtpDaemon::SourceUnsupported, "accepts only one source" if @inputs.size >1

      @input = @inputs.first
      raise RestFtpDaemon::SourceUnsupported, @input.scheme unless @input.is? URI::FILE
    end

    def work
      work_debug
    end

  protected

  end
end