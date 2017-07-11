module RestFtpDaemon::Task
  class Export < Base

    # Task attributes
    def task_icon
      "arrow-up"
    end

    # Task statuses
    STATUS_CONNECTING    = "export-connect"
    STATUS_CHDIR         = "export-chdir"
    STATUS_UPLOADING     = "export-upload"
    STATUS_RENAMING      = "export-rename"
    STATUS_DISCONNECTING = "export-disconnect"

    # Task operations
    def prepare      
      # Check output target
      log_debug "prepare", {
        target_loc:     target_loc.to_s,
        flag_mkdir:     get_flag(:mkdir),
        flag_overwrite: get_flag(:overwrite),
        flag_tempfile:  get_flag(:tempfile),
        }

      # Guess target file name, and fail if present while we matched multiple sources
      if target_loc.name && @input.count > 1
        raise RestFtpDaemon::TargetDirectoryError, "prepare: target should be a directory when severeal files matched"
      end

      # Some init
      @transfer_sent = 0
      set_info INFO_SOURCE_PROCESSED, 0

      # Prepare remote object
      remote_class = case target_loc.uri
      when URI::FTP               then Remote::RemoteFTP
      when URI::FTPES, URI::FTPS  then Remote::RemoteFTP
      when URI::SFTP              then Remote::RemoteSFTP
      when URI::S3                then Remote::RemoteS3
      when URI::FILE              then Remote::RemoteFile
      else
        log_error "prepare: method unknown: #{target_loc.uri.class.name}"
        raise RestFtpDaemon::TargetUnsupported, "unknown scheme [#{target_loc.scheme}]"
      end

      # Create remote
      @remote = remote_class.new target_loc, @job, @config
    end

    def process
      # Connect to remote server and login
      set_status STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status STATUS_CHDIR
      @remote.chdir_or_create target_loc.dir_abs, get_flag(:mkdir)

      # Compute total files size
      @transfer_total = @input.collect(&:size).sum
      set_info INFO_TRANSFER_TOTAL, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      @source_processed = 0

      # Do the transfer, for each file
      @input.each do |input|
        remote_upload input, get_flag(:tempfile), get_flag(:overwrite)
      end
    end

    def finalize
      # Close FTP connexion and free up memory
      @remote.close if @remote

      # Free @remote object
      @remote = nil

      # Update job status
      set_status STATUS_DISCONNECTING
      @finished_at = Time.now

      RestFtpDaemon::Counters.instance.add :data, :transferred, @transfer_total
    end

  private

    def remote_upload source, tempfile = true, overwrite = false
      # Method assertions
      raise RestFtpDaemon::AssertionFailed, "remote_upload/remote" if @remote.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/source" if source.nil?

      # Build target
      target = target_loc.named_like(source)

      # Set target name
      set_info INFO_CURRENT, target.name

      # Build temp target if necessary
      if tempfile
        destination = target_loc.named_like(source, true)
        log_debug "remote_upload: use tempfile", {
          source: source.name,
          destination: destination.name,
          target: target.name,
          }
      else
        destination = target
        log_debug "remote_upload: no tempfile", {
          source: source.name,
          target: target.name,
          }
      end

      # Remove any existing version if present, or check if it's there
      if overwrite
        @remote.remote_try_delete target
      elsif (size = @remote.size_if_exists(target))  # won't be triggered when NIL or 0 is returned
        log_debug "remote_upload: file exists (#{format_bytes size, 'B'})"
        raise RestFtpDaemon::TargetFileExists
      end

      # Start transfer
      transfer_started_at = Time.now
      @last_notify_at = transfer_started_at

      # Start the transfer, update job status after each block transfer
      set_status STATUS_UPLOADING
      @remote.push source, destination do |transferred, name|
        progress_update transferred, name
      end

      # Explicitely send a 100% notification
      progress_notify 100, destination.name, true

      # Compute final bitrate
      global_transfer_bitrate = progress_bitrate_delta @transfer_total, (Time.now - transfer_started_at)
      set_info INFO_TRANFER_BITRATE, global_transfer_bitrate.round(0)

      # Rename file to target name
      if tempfile
        log_info "remote_upload: rename [#{destination.name}] > [#{target.name}]"
        @remote.move destination, target
      end

      # Add it to transferred target names
      set_info INFO_TARGET_FILES, @output.collect(&:name)

      # Update counters
      set_info INFO_SOURCE_PROCESSED, @source_processed += 1
      set_info INFO_CURRENT, nil
    end    

  end
end
