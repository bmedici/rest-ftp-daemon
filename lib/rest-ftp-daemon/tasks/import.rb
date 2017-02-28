module RestFtpDaemon
  class TaskImport < Task

    # Task attributes
    ICON = "import"

    def do_before
      # Check input
      # @input = @job.source_loc.clone
      unless source_loc.is_a?(Location) && source_loc.uri_is?(URI::FILE)
        raise RestFtpDaemon::SourceUnsupported, source_loc.scheme
      end
      dump_locations "source_loc", [source_loc]
    end

    def do_work
      # Scan local source files from disk
      set_status Job::STATUS_IMPORT_LISTING
      files = source_loc.local_files
      set_info INFO_SOURCE_COUNT, files.size
      set_info INFO_SOURCE_FILES, files.collect(&:name)
      log_info "local_files", files.collect(&:name)
      raise RestFtpDaemon::SourceNotFound if files.empty?

      @outputs.concat files
    end

    def do_after
    end

  protected

  end
end
