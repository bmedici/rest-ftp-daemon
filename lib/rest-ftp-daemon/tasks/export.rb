module RestFtpDaemon
  class TaskExport < Task
    include TransferHelpers

    def do_before
      # Init
      super
      @output = @outputs.first

      # Check source
      if @outputs.size>1
        raise RestFtpDaemon::TargetUnsupported, "accepts only one target"
      end

return

      # Guess target file name, and fail if present while we matched multiple sources
      if @inputs.count<1
        raise RestFtpDaemon::SourceUnsupported, "should receive at least one source"
      end
      if @output.name && @inputs.count>1
        raise RestFtpDaemon::TargetDirectoryError, "target should be a directory when matching many files"
      end

      # Some init
      @transfer_sent = 0
      set_info INFO_SOURCE_PROCESSED, 0
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
    end

    def work
      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status JOB_STATUS_CHDIR
      #log_info "do_work chdir_or_create #{@output.filedir}"
      @remote.chdir_or_create @output.dir_fs, get_option(:transfer, :mkdir)

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
        # Build final target, add the source file name if noneh
        target = @output.clone
        target.name = source.name unless target.name

        # Do the transfer, for each file
        remote_upload source, target, get_option(:transfer, :overwrite)

      #work_debug
    end

  protected

  end
end
