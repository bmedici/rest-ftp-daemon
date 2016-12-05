module RestFtpDaemon
  class TaskExport < Task
    def do_before
      super

      # Check source
      raise RestFtpDaemon::TargetUnsupported, "accepts only one target" if @outputs.size>1

      # Guess target file name, and fail if present while we matched multiple sources
      @output = @outputs.first
      raise RestFtpDaemon::TargetDirectoryError, "target should be a directory when matching many files" if @output.name && @inputs.count>1
    end

    def work
      work_debug
    end

  protected

  end
end