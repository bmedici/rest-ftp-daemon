module RestFtpDaemon::Task
  class ImportError        < TaskError; end

  class TaskImport < TaskBase

    # Task statuses
    STATUS_LISTING       = "import-list"
    STATUS_DOWNLOADING   = "import-download"   

    # Task info
    def task_icon
      "arrow-down"
    end
    def task_name
      "import"
    end

    def prepare
      # raise Task::TaskImportError, "this is a fake task error from RestFtpDaemon::Task::TaskImport"
    end

    # Task operations
    def process
      set_status Task::TaskImport::STATUS_LISTING

      # Check input conformity
      unless source_loc.is_a?(Location) && source_loc.uri_is?(URI::FILE)
        raise Task::TargetUnsupported, "unknown scheme [#{source_loc.scheme}] [#{source_loc.uri.class.name}]"
      end

      # Scan local source files from disk
      files = source_loc.local_files
      set_info INFO_SOURCE_FILES, files.collect(&:name)

      # Check we matched at least one file
      raise Task::SourceNotFound if files.empty?

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
