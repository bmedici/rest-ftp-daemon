module RestFtpDaemon
  class TaskImport < Task

    # Task attributes
    ICON = "import"

    def prepare
      # I can accept only one input
      unless @inputs.size == 1
        raise RestFtpDaemon::SourceUnsupported, "cannot accept more than one input"
      end
      @input = @inputs.first

      # Check input conformity
      unless @input.is_a?(Location) && @input.uri_is?(URI::FILE)
        raise RestFtpDaemon::SourceUnsupported, @input.scheme
      end
      # log_debug "input: #{@input.to_s}"
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
