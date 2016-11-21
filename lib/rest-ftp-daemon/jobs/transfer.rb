#FIXME: move progress from Job/infos/transfer to Job/progress

module RestFtpDaemon
  class JobTransfer < Job

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
        log_info "JobTransfer.do_before target_method FTP"
        @remote = Remote::RemoteFTP.new @target_loc, log_context, @config[:debug_ftp]
      when URI::FTPES, URI::FTPS
        log_info "JobTransfer.do_before target_method FTPES/FTPS"
        @remote = Remote::RemoteFTP.new @target_loc, log_context, @config[:debug_ftps], :ftpes
      when URI::SFTP
        log_info "JobTransfer.do_before target_method SFTP"
        @remote = Remote::RemoteSFTP.new @target_loc, log_context, @config[:debug_sftp]
      when URI::S3
        log_info "JobTransfer.do_before target_method S3"
        @remote = Remote::RemoteS3.new @target_loc, log_context, @config[:debug_s3]
      else
        message = "unknown scheme [#{@target_loc.scheme}] [#{target_uri.class.name}]"
        log_info "JobTransfer.do_before #{message}"
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
      log_info "JobTransfer.do_work sources #{sources.collect(&:name)}"
      raise RestFtpDaemon::SourceNotFound if sources.empty?

      # Guess target file name, and fail if present while we matched multiple sources
      raise RestFtpDaemon::TargetDirectoryError if @target_loc.name && sources.count>1

      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status JOB_STATUS_CHDIR
      #log_info "JobTransfer.do_work chdir_or_create #{@target_loc.filedir}"
      @remote.chdir_or_create @target_loc.filedir, @mkdir

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
      log_info "JobTransfer.do_after close connexion, update status and counters"
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

    def remote_upload source, target
      # Method assertions
      raise RestFtpDaemon::AssertionFailed, "remote_upload/remote" if @remote.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/source" if source.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/target" if target.nil?

      # Use source filename if target path provided none (typically with multiple sources)
      log_info "remote_upload temp[#{@tempfile}] source[#{source.path}] target[#{target.path}]"
      set_info INFO_SOURCE_CURRENT, source.name

      # Remove any existing version if present, or check if it's there
      if @overwrite
        @remote.remove! target
      elsif (size = @remote.size_if_exists(target))  # won't be triggered when NIL or 0 is returned
        log_debug "remote_upload file exists ! (#{format_bytes size, 'B'})"
        raise RestFtpDaemon::TargetFileExists
      end

      # Start transfer
      transfer_started_at = Time.now
      @last_notify_at = transfer_started_at

      # Start the transfer, update job status after each block transfer
      set_status JOB_STATUS_UPLOADING
      log_debug "JobTransfer.remote_upload source[#{source.path}] temp[#{@tempfile}]"
      @remote.upload source, target, @tempfile do |transferred, name|
        # Update transfer statistics
        update_progress transferred, name
      end

      # Compute final bitrate
      global_transfer_bitrate = get_bitrate @transfer_total, (Time.now - transfer_started_at)
      set_info INFO_TRANFER_BITRATE, global_transfer_bitrate.round(0)

      # Done
      set_info INFO_SOURCE_CURRENT, nil
    end

    def update_progress transferred, name = ""
      # Update counters
      @transfer_sent += transferred
      set_info INFO_TRANFER_SENT, @transfer_sent

      # Update job info
      percent0 = (100.0 * @transfer_sent / @transfer_total).round(0)
      set_info INFO_TRANFER_PROGRESS, percent0

      # Update bitrates
      @current_bitrate = running_bitrate @transfer_sent
      set_info INFO_TRANFER_BITRATE,  @current_bitrate.round(0)

      # What's current time ?
      now = Time.now

      # Notify if requested
      progress_notify now, percent0, name

      # Touch my worker status
      touch_job
    end

  private

    def progress_notify now, percent0, name
      # No delay provided ?
      return if @config[:notify_after].nil?

      # Still too early to notify again ?
      how_long_ago = (now.to_f - @last_notify_at.to_f)
      return unless how_long_ago > @config[:notify_after]

      # # Update bitrates
      # @current_bitrate = running_bitrate @transfer_sent
      # set_info INFO_TRANFER_BITRATE,  @current_bitrate.round(0)

      # Log progress
      stack = [
        "#{percent0} %",
        format_bytes(@transfer_sent, "B"),
        format_bytes(@current_bitrate.round(0), "bps")
        ]
      stack2 = stack.map { |txt| ("%#{LOG_PIPE_LEN.to_i}s" % txt) }.join("\t")
      log_debug "progress #{stack2} \t#{name}"

      # Prepare and send notification
      client_notify :progress, status: {
        progress: percent0,
        transfer_sent: @transfer_sent,
        transfer_total: @transfer_total,
        transfer_bitrate: @current_bitrate.round(0),
        transfer_current: name,
        }

      # Remember when we last did it
      @last_notify_at = now
    end

    def get_bitrate delta_data, delta_time
      return nil if delta_time.nil? || delta_time.zero?
      8 * delta_data.to_f.to_f / delta_time
    end

    def running_bitrate current_data
      return if @last_time.nil?

      # Compute deltas
      @last_data ||= 0
      delta_data = current_data - @last_data
      delta_time = Time.now - @last_time

      # Update counters
      @last_time = Time.now
      @last_data = current_data

      # Return bitrate
      get_bitrate delta_data, delta_time
    end
  end

  # NewRelic instrumentation
  # add_transaction_tracer :prepare,        category: :task
  # add_transaction_tracer :run,            category: :task

end