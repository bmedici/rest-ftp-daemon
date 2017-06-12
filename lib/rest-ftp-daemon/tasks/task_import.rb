module RestFtpDaemon
  class TaskImport < Task

    # Task attributes
    ICON = "import"

      # Check input
      # @input = @job.source_loc.clone
      unless source_loc.is_a?(Location) && source_loc.uri_is?(URI::FILE)
        raise RestFtpDaemon::SourceUnsupported, source_loc.scheme
    def prepare
      end
      log_debug "source_loc: #{source_loc.to_s}"
    end

    def process
      # Scan local source files from disk
      set_status Job::STATUS_IMPORT_LISTING
      files = source_loc.local_files

      # Sump some informations
      set_info INFO_SOURCE_COUNT, files.size
      set_info INFO_SOURCE_FILES, files.collect(&:name)

      # Check we matched at least one file
      raise RestFtpDaemon::SourceNotFound if files.empty?

      # Add file to output
      files.each do |file|
        add_output file
      end
    end

    def finalize
    end

  protected

  end
end
