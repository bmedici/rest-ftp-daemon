module RestFtpDaemon
  class TaskImport < Task

    # Task attributes
    def task_icon
      "arrow-down"
    end

    # Task statuses
    STATUS_IMPORT_LISTING       = "import-list"

    # Task operations
    def process
      set_status TaskImport::STATUS_IMPORT_LISTING

      # Check input conformity
      unless source_loc.is_a?(Location) && source_loc.uri_is?(URI::FILE)
        raise RestFtpDaemon::SourceUnsupported, source_loc.scheme
      end

      # Scan local source files from disk
      files = source_loc.local_files
      set_info INFO_SOURCE_COUNT, files.size
      set_info INFO_SOURCE_FILES, files.collect(&:name)

      # Check we matched at least one file
      raise RestFtpDaemon::SourceNotFound if files.empty?

      # Add file to output
      files.each do |file|
        log_info "matched: #{file.path_rel}"
        add_output file
      end
    end

  protected

    def process_unit unit
    end

  end
end
