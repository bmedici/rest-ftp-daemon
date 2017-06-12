module RestFtpDaemon
  class TaskExport < Task
    include TransferHelpers

    # Task attributes
    ICON = "export"

    def do_before
      # Check input
      @inputs = @job.stash.clone
      unless @inputs.is_a? Array
        raise RestFtpDaemon::SourceUnsupported, "task inputs: invalid file list"
      end

      # Check outputs
      unless target_loc.uri_is? URI::FILE
        raise RestFtpDaemon::TargetUnsupported, "task output: invalid file type"
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
        # options[:debug] = @config[:debug_ftp]
        @remote = Remote::RemoteFTP.new target_loc, log_context, @config[:debug_ftp]
      when URI::FTPES, URI::FTPS
        log_info "do_before target_method FTPES/FTPS"
        @remote = Remote::RemoteFTP.new target_loc, log_context, @config[:debug_ftps], :ftpes
      when URI::SFTP
        log_info "do_before target_method SFTP"
        @remote = Remote::RemoteSFTP.new target_loc, log_context, @config[:debug_sftp]
      when URI::S3
        log_info "do_before target_method S3"
        @remote = Remote::RemoteS3.new target_loc, log_context, @config[:debug_s3]
      when URI::FILE
        log_info "do_before target_method FILE"
        @remote = Remote::RemoteFile.new target_loc, log_context, @config[:debug_file]
      else
        message = "unknown scheme [#{target_loc.scheme}] [#{target_uri.class.name}]"
        log_info "do_before #{message}"
        raise RestFtpDaemon::TargetUnsupported, message
      end

      # Plug this Job into @remote to allow it to log
      @remote.job = self.job
    end

    def do_work
      # outputs = []

      # Connect to remote server and login
      set_status Job::STATUS_EXPORT_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status Job::STATUS_EXPORT_CHDIR
      @remote.chdir_or_create target_loc.dir_abs, get_option(:transfer, :mkdir)

      # Compute total files size
      @transfer_total = @inputs.collect(&:size).sum
      set_info INFO_TRANSFER_TOTAL, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []

      log_debug "export_inputs (outside)", @inputs.collect(&:to_s)
      @inputs.each do |source|
        log_debug "each: #{source.path_abs} = #{source.to_s}"
        log_debug "export_inputs (inside)", @inputs.collect(&:to_s)

next
        # Build final target, add the source file name if noneh
        target = target_loc.clone
        target.name = source.name.clone unless target.name

        # Do the transfer, for each file
        log_info "do_work each: source2: #{source.path_abs}"
        log_info "do_work each: target2: #{target.path_abs}"
        remote_upload source, target, get_option(:transfer, :overwrite)

        # Add it to transferred target names
        targets << target.name
        set_info INFO_TARGET_FILES, targets

        # Update counters
        set_info INFO_SOURCE_PROCESSED, source_processed += 1

        # Add file to output
        add_output target
      end
    end

    def do_after
      # Close FTP connexion and free up memory
      # log_info "do_after close connexion, update status and counters"
      @remote.close if @remote

      # Free @remote object
      @remote = nil

      # Update job status
      set_status Job::STATUS_EXPORT_DISCONNECTING
      @finished_at = Time.now

      RestFtpDaemon::Counters.instance.add :data, :transferred, @transfer_total
    end

  end
end
