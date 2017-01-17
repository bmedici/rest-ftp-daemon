#FIXME: move progress from Job/infos/transfer to Job/progress

module RestFtpDaemon
  class JobTransfer < Job
    include TransferHelpers

  protected

    def do_before
      # Prepare flags
      flag_prepare :mkdir
      flag_prepare :overwrite
      flag_prepare :tempfile

      # Some init
      @transfer_sent = 0
      set_info INFO_SOURCE_PROCESSED, 0

      # Ensure source is FILE
      raise RestFtpDaemon::SourceUnsupported, @source_loc.scheme   unless @source_loc.is? URI::FILE

      # Prepare remote object
      case target_uri
      when URI::FTP
        log_info "do_before target_method FTP"
        @remote = Remote::RemoteFTP.new @target_loc, log_context, @config[:debug_ftp]
      when URI::FTPES, URI::FTPS
        log_info "do_before target_method FTPES/FTPS"
        @remote = Remote::RemoteFTP.new @target_loc, log_context, @config[:debug_ftps], :ftpes
      when URI::SFTP
        log_info "do_before target_method SFTP"
        @remote = Remote::RemoteSFTP.new @target_loc, log_context, @config[:debug_sftp]
      when URI::S3
        log_info "do_before target_method S3"
        @remote = Remote::RemoteS3.new @target_loc, log_context, @config[:debug_s3]
      else
        message = "unknown scheme [#{@target_loc.scheme}] [#{target_uri.class.name}]"
        log_info "do_before #{message}"
        raise RestFtpDaemon::TargetUnsupported, message
      end

      # Plug this Job into @remote to allow it to log
      @remote.job = self

    # rescue URI::InvalidURIError => exception
    #   return oops :started, exception, "target_invalid"
    end

    def do_work
      # Scan local source files from disk
      set_status JOB_STATUS_CHECKING_SRC
      sources = @source_loc.local_files
      set_info INFO_SOURCE_COUNT, sources.size
      set_info INFO_SOURCE_FILES, sources.collect(&:name)
      log_info "do_work sources #{sources.collect(&:name)}"
      raise RestFtpDaemon::SourceNotFound if sources.empty?

      # Guess target file name, and fail if present while we matched multiple sources
      raise RestFtpDaemon::TargetDirectoryError if @target_loc.name && sources.count>1

      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status JOB_STATUS_CHDIR
      #log_info "do_work chdir_or_create #{@target_loc.dir_fs}"
      @remote.chdir_or_create @target_loc.dir_fs, @mkdir

      # Compute total files size
      @transfer_total = sources.collect(&:size).sum
      set_info INFO_TRANSFER_TOTAL, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []
      sources.each do |source|
        # Build final target, add the source file name if noneh
        target = @target_loc.clone
        target.name = source.name unless target.name

        # Do the transfer, for each file
        remote_upload source, target

        # Add it to transferred target names
        targets << target.name
        set_info INFO_TARGET_FILES, targets

        # Update counters
        set_info INFO_SOURCE_PROCESSED, source_processed += 1
      end
    end

    def do_after
      # Close FTP connexion and free up memory
      log_info "do_after close connexion, update status and counters"
      @remote.close

      # Free @remote object
      @remote = nil

      # Update job status
      set_status JOB_STATUS_DISCONNECTING
      @finished_at = Time.now

      # Update counters
      RestFtpDaemon::Counters.instance.increment :jobs, :finished
      RestFtpDaemon::Counters.instance.add :data, :transferred, @transfer_total
    end

  # NewRelic instrumentation
  # add_transaction_tracer :prepare,        category: :task
  # add_transaction_tracer :run,            category: :task
  end
end