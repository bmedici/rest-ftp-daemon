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
      # Scan local source files from disk
      set_status set_status_CHECKING_SRC
      files = @input.local_files
      set_info INFO_SOURCE_COUNT, files.size
      set_info INFO_SOURCE_FILES, files.collect(&:name)
      log_info "local_files", files.collect(&:name)
      raise RestFtpDaemon::SourceNotFound if files.empty?

      # Sources are OK
      @outputs.concat files
    end

    def do_after
      # # Guess target file name, and fail if present while we matched multiple sources
      # raise RestFtpDaemon::TargetDirectoryError, "target should be a directory when matching many files" if @target_loc.name && sources.count>1
    end

  protected

  end
end