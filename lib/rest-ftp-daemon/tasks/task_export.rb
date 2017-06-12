module RestFtpDaemon
  class TaskExport < Task

    # Task attributes
    ICON = "export"

    def prepare

      unless target_loc.uri_is? URI::FILE
        raise RestFtpDaemon::TargetUnsupported, "task output: invalid file type"
      # Check output
      end
      log_debug "target_loc: #{target_loc.to_s}"

      # Guess target file name, and fail if present while we matched multiple sources
      if target_loc.name && @inputs.count>1
        raise RestFtpDaemon::TargetDirectoryError, "target should be a directory if severeal files matched"
      end

      # Some init
      @transfer_sent = 0
      set_info INFO_SOURCE_PROCESSED, 0
      # Prepare remote object
      case target_loc.uri
      when URI::FTP
        log_info "do_before target_method FTP"
        @remote = Remote::RemoteFTP.new @output, @job, @config
      when URI::FTPES, URI::FTPS
        log_info "do_before target_method FTPES/FTPS"
        @remote = Remote::RemoteFTP.new @output, @job, @config, :ftpes
      when URI::SFTP
        log_info "do_before target_method SFTP"
        @remote = Remote::RemoteSFTP.new @output, @job, @config
      when URI::S3
        log_info "do_before target_method S3"
        @remote = Remote::RemoteS3.new @output, @job, @config
      when URI::FILE
        log_info "do_before target_method FILE"
        @remote = Remote::RemoteFile.new @output, @job, @config
      else
        message = "unknown scheme [#{target_loc.scheme}] [#{target_uri.class.name}]"
        log_info "do_before #{message}"
        raise RestFtpDaemon::TargetUnsupported, message
      end

      # Plug this Job into @remote to allow it to log
      @remote.job = self.job
    end

    def process
      # Connect to remote server and login
      set_status Job::STATUS_EXPORT_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status Job::STATUS_EXPORT_CHDIR
      @remote.chdir_or_create @output.dir_abs, get_option(:transfer, :mkdir)

      # Compute total files size
      @transfer_total = @inputs.collect(&:size).sum
      set_info INFO_TRANSFER_TOTAL, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []

      @inputs.each do |source|
        log_debug "source[#{source.name}] > target[#{source.name}]"

        # Build final target, add the source file name if noneh
        target = @output.clone
        target.name = source.name.clone unless target.name

        # Do the transfer, for each file
        remote_upload source, target, get_option(:transfer, :overwrite)

        # Add it to transferred target names
        targets << target.name
        set_info INFO_TARGET_FILES, targets

        # Update counters
        set_info INFO_SOURCE_PROCESSED, source_processed += 1

        # Add file to output
        output_add target
        log_debug "stashed target: #{target.to_s}"
      end
    end

    def finalize
      # Close FTP connexion and free up memory
      @remote.close if @remote

      # Free @remote object
      @remote = nil

      # Update job status
      set_status Job::STATUS_EXPORT_DISCONNECTING
      @finished_at = Time.now

      RestFtpDaemon::Counters.instance.add :data, :transferred, @transfer_total
    end

  private

    def remote_upload source, target, overwrite = false
      # Method assertions
      raise RestFtpDaemon::AssertionFailed, "remote_upload/remote" if @remote.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/source" if source.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/target" if target.nil?

      # Use source filename if target path provided none (typically with multiple sources)
      log_info "Task.remote_upload", {
        source_abs: source.path_abs,
        target_rel: target.path_rel,
        overwrite:  overwrite,
        tempfile:   @tempfile,
        }
      set_info INFO_SOURCE_CURRENT, source.name

      # Remove any existing version if present, or check if it's there
      if overwrite
        @remote.try_to_remove target
      elsif (size = @remote.size_if_exists(target))  # won't be triggered when NIL or 0 is returned
        log_debug "Task.remote_upload file exists ! (#{format_bytes size, 'B'})"
        raise RestFtpDaemon::TargetFileExists
      end

      # Generate temp file
      if @tempfile
        destination = target.clone
        destination.generate_temp_name!
      else
        destination = target
      end

      # Start transfer
      transfer_started_at = Time.now
      @last_notify_at = transfer_started_at

      # Start the transfer, update job status after each block transfer
      set_status Job::STATUS_EXPORT_UPLOADING
      log_debug "Task.remote_upload: upload [#{source.name}] > [#{destination.name}]"
      @remote.upload source, destination do |transferred, name|
        # Update transfer statistics
        progress_update transferred, name
      end

      # Compute final bitrate
      global_transfer_bitrate = progress_bitrate_delta @transfer_total, (Time.now - transfer_started_at)
      set_info INFO_TRANFER_BITRATE, global_transfer_bitrate.round(0)

      # Rename file to target name
      if @tempfile
        log_debug "Task.remote_upload: rename [#{destination.name}] > [#{target.name}]"
        @remove.move destination, target
      end

      # Done
      set_info INFO_SOURCE_CURRENT, nil
    end    

  end
end
