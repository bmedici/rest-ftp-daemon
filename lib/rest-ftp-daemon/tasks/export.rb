module RestFtpDaemon
  class TaskExport < Task
    include TransferHelpers

    def do_before
      super

      # Check source
      raise RestFtpDaemon::TargetUnsupported, "accepts only one target" if @outputs.size>1

      # Guess target file name, and fail if present while we matched multiple sources
      @output = @outputs.first
      raise RestFtpDaemon::TargetDirectoryError, "target should be a directory when matching many files" if @output.name && @inputs.count>1

return

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

      #work_debug
    end

  protected

  end
end