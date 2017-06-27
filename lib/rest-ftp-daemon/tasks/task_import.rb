module RestFtpDaemon
  class TaskImport < Task

    # Task attributes
    def task_icon
      "arrow-down"
    end

    # Task operations
    def prepare
      # Check input conformity
      unless @job.source_loc.is_a?(Location) && @job.source_loc.uri_is?(URI::FILE)
        raise RestFtpDaemon::SourceUnsupported, @job.source_loc.scheme
      end
    end

    def process
      # Scan local source files from disk
      set_status Job::STATUS_IMPORT_LISTING
      files = @input.local_files

      # Sump some informations
      set_info INFO_SOURCE_COUNT, files.size
      set_info INFO_SOURCE_FILES, files.collect(&:name)

      # Check we matched at least one file
      raise RestFtpDaemon::SourceNotFound if files.empty?

      # Add file to output
      files.each do |file|
        output_add file
      end
    end

    def finalize
    end

  protected

  end
end
