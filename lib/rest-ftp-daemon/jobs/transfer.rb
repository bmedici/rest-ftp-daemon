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
      set_info :source, :processed, 0

      # Ensure source is FILE
      raise RestFtpDaemon::SourceNotSupported, @source_loc.scheme   unless source_uri.is_a? URI::FILE

      # Prepare remote object
      case target_uri
      when URI::FTP
        log_info "JobTransfer.before target_method FTP"
        @remote = RemoteFTP.new @target_loc, log_prefix, @config[:debug_ftps]
      when URI::FTPES, URI::FTPS
        log_info "JobTransfer.before target_method FTPES/FTPS"
        @remote = RemoteFTP.new @target_loc, log_prefix, @config[:debug_ftps], :ftpes
      when URI::SFTP
        log_info "JobTransfer.before target_method SFTP"
        @remote = RemoteSFTP.new @target_loc, log_prefix, @config[:debug_sftp]
      when URI::S3
        log_info "JobTransfer.before target_method S3"
        @remote = RemoteS3.new @target_loc, log_prefix, @config[:debug_s3]
      else
        log_info "JobTransfer.before unknown scheme [#{@target_loc.scheme}]"
        raise RestFtpDaemon::TargetNotSupported, @target_loc.scheme
      end

      # Plug this Job into @remote to allow it to log
      @remote.job = self

    # rescue URI::InvalidURIError => exception
    #   return oops :started, exception, "target_invalid"
    end

    def do_work
      # Scan local source files from disk
      set_status JOB_STATUS_CHECKING_SRC
      sources = @source_loc.scan_files
      log_debug "JobTransfer.work sources result #{sources.inspect}"
      set_info :source, :count, sources.size
      set_info :source, :files, sources.collect(&:name)
      log_info "JobTransfer.work sources names #{sources.collect(&:name)}"
      raise RestFtpDaemon::SourceNotFound if sources.empty?

      # Guess target file name, and fail if present while we matched multiple sources
      raise RestFtpDaemon::TargetDirectoryError if @target_loc.name && sources.count>1

      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status JOB_STATUS_CHDIR
      @remote.chdir_or_create @target_loc.dir, @mkdir

      # Compute total files size
      @transfer_total = sources.collect(&:size).sum
      set_info :work, :total, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []
      sources.each do |source|
        # Compute target filename
        target_final = @target_loc.clone

        # Add the source file name if none found in the target path
        unless target_final.name
          target_final.name = source.name
        end

        # Do the transfer, for each file
        remote_push source, target_final

        # Add it to transferred target names
        targets << target_final.path
        set_info :target, :files, targets

        # Update counters
        set_info :source, :processed, source_processed += 1
      end
    end

    def do_after
      # Close FTP connexion and free up memory
      log_info "JobTransfer.after"
      @remote.close

      # Free-up remote object
      @remote = nil

      # Update job status
      set_status JOB_STATUS_DISCONNECTING
      @finished_at = Time.now

      # Update counters
      RestFtpDaemon::Counters.instance.increment :jobs, :finished
      RestFtpDaemon::Counters.instance.add :data, :transferred, @transfer_total
    end

    def remote_push source, target
      # Method assertions
      raise RestFtpDaemon::AssertionFailed, "remote_push/remote" if @remote.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_push/source" if source.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_push/target" if target.nil?

      # Use source filename if target path provided none (typically with multiple sources)
      log_info "JobTransfer.remote_push [#{source.name}]: [#{source.path}] > [#{target.path}]"
      set_info :source, :current, source.name

      # Compute temp target name
      tempname = nil
      if @tempfile
        tempname = "#{target.name}.temp-#{identifier(JOB_TEMPFILE_LEN)}"
        log_debug "JobTransfer.remote_push tempname [#{tempname}]"
      end

      # Remove any existing version if expected, or test its presence
      if @overwrite
        @remote.remove! target
      elsif size = @remote.present?(target)
        log_debug "JobTransfer.remote_push existing (#{format_bytes size, 'B'})"
        raise RestFtpDaemon::TargetFileExists
      end

      # Start transfer
      transfer_started_at = Time.now
      @progress_at = 0
      @notified_at = transfer_started_at

      # Start the transfer, update job status after each block transfer
      set_status JOB_STATUS_UPLOADING
      @remote.push source, target, tempname do |transferred, name|
        # Update transfer statistics
        progress transferred, name

        # Touch my worker status
        touch_job
      end

      # Compute final bitrate
      global_transfer_bitrate = get_bitrate @transfer_total, (Time.now - transfer_started_at)
      set_info :work, :bitrate, global_transfer_bitrate.round(0)

      # Done
      set_info :source, :current, nil
    end

    def progress transferred, name = ""
      # What's current time ?
      now = Time.now
      notify_after = @config[:notify_after]

      # Update counters
      @transfer_sent += transferred
      set_info :work, :sent, @transfer_sent

      # Update job info
      percent0 = (100.0 * @transfer_sent / @transfer_total).round(0)
      set_info :work, :progress, percent0

      # Update job status after each NOTIFY_UPADE_STATUS
      progressed_ago = (now.to_f - @progress_at.to_f)
      if (!JOB_UPDATE_INTERVAL.to_f.zero?) && (progressed_ago > JOB_UPDATE_INTERVAL.to_f)
        @current_bitrate = running_bitrate @transfer_sent
        set_info :work, :bitrate, @current_bitrate.round(0)

        # Log progress
        stack = []
        stack << "#{percent0} %"
        stack << (format_bytes @transfer_sent, "B")
        stack << (format_bytes @transfer_total, "B")
        stack << (format_bytes @current_bitrate.round(0), "bps")
        stack2 = stack.map { |txt| ("%#{LOG_PIPE_LEN.to_i}s" % txt) }.join("\t")
        log_debug "progress #{stack2} \t#{name}"

        # Remember when we last did it
        @progress_at = now
      end

      # Notify if requested
      notified_ago = (now.to_f - @notified_at.to_f)
      if (!notify_after.nil?) && (notified_ago > notify_after)
        # Prepare and send notification
        notif_status = {
          progress: percent0,
          transfer_sent: @transfer_sent,
          transfer_total: @transfer_total,
          transfer_bitrate: @current_bitrate.round(0),
          }
        client_notify :progress, status: notif_status

        # Remember when we last did it
        @notified_at = now
      end
    end

  private

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
