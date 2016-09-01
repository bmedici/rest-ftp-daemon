module RestFtpDaemon
  class JobTransfer < Job

    def initialize job_id, params = {}
      super
    end

    def process
      log_info "JobTransfer.process update_interval:#{JOB_UPDATE_INTERVAL}"

      # Prepare job
      begin
        prepare_common
        prepare_local

      else
        # Prepare done !
        set_status JOB_STATUS_PREPARED
      end

      # Process job
      begin
        log_info "JobTransfer.process notify [started]"
        client_notify :started
        #return oops :ended, Exception.new, "ftp_perm_error"
        run
      else
        # All done !
        set_status JOB_STATUS_FINISHED
        log_info "Job.process notify [ended]"
        client_notify :ended
      end
    end

  protected

    def before
      # Prepare flags
      flag_prepare :mkdir, false
      flag_prepare :overwrite, false
      flag_prepare :tempfile, true

      # Prepare remote (case would be preferable but too hard to use,
      # as target could be of a descendent class of URI:XXX and not matching directly)
      if @target_uri.is_a? URI::FTP
        log_info "Job.prepare target_method FTP"
        set_info :target, :method, JOB_METHOD_FTP
        @remote = RemoteFTP.new @target_uri, log_prefix, debug: @config[:debug_ftp]

      elsif (@target_uri.is_a? URI::FTPES) || (target_uri.is_a? URI::FTPS)
        log_info "Job.prepare target_method FTPES"
        set_info :target, :method, JOB_METHOD_FTPS
        @remote = RemoteFTP.new @target_uri, log_prefix, debug: @config[:debug_ftps], ftpes: true

      elsif @target_uri.is_a? URI::SFTP
        log_info "Job.prepare target_method SFTP"
        set_info :target, :method, JOB_METHOD_SFTP
        @remote = RemoteSFTP.new @target_uri, log_prefix, debug: @config[:debug_sftp]

      else
        log_info "Job.prepare unknown scheme [#{@target_uri.scheme}]"
        raise RestFtpDaemon::JobTargetUnsupported

      end
    end

    rescue RestFtpDaemon::AssertionFailed => exception
      return oops :started, exception

    # rescue URI::InvalidURIError => exception
    #   return oops :started, exception, "target_invalid"
    end

      # Guess source files from disk
    def work
      set_status JOB_STATUS_CHECKING_SRC
      sources = find_local @source_path
      set_info :source, :count, sources.count
      set_info :source, :files, sources.collect(&:full)
      log_info "Job.run sources #{sources.collect(&:name)}"
      raise RestFtpDaemon::JobSourceNotFound if sources.empty?

      # Guess target file name, and fail if present while we matched multiple sources
      raise RestFtpDaemon::JobTargetDirectoryError if @target_path.name && sources.count>1

      # Connect to remote server and login
      set_status JOB_STATUS_CONNECTING
      @remote.connect

      # Prepare target path or build it if asked
      set_status JOB_STATUS_CHDIR
      @remote.chdir_or_create @target_path.dir, @mkdir

      # Compute total files size
      @transfer_total = sources.collect(&:size).sum
      set_info :transfer, :total, @transfer_total

      # Reset counters
      @last_data = 0
      @last_time = Time.now

      # Handle each source file matched, and start a transfer
      source_processed = 0
      targets = []
      sources.each do |source|
        # Compute target filename
        full_target = @target_path.clone

        # Add the source file name if none found in the target path
        unless full_target.name
          full_target.name = source.name
        end

        # Do the transfer, for each file
        remote_push source, full_target

        # Add it to transferred target names
        targets << full_target.full
        set_info :target, :files, targets

        # Update counters
        set_info :source, :processed, source_processed += 1
      end

    rescue SocketError => exception
      return oops :ended, exception, "conn_socket_error"

    rescue EOFError => exception
      return oops :ended, exception, "conn_eof"

    rescue Errno::EHOSTDOWN => exception
      return oops :ended, exception, "conn_host_is_down"

    rescue Errno::EPIPE=> exception
      return oops :ended, exception, "conn_broken_pipe"

    rescue Errno::ENETUNREACH => exception
      return oops :ended, exception, "conn_unreachable"

    rescue Errno::ECONNRESET => exception
      return oops :ended, exception, "conn_reset_by_peer"

    rescue Errno::ENOTCONN => exception
      return oops :ended, exception, "conn_failed"

    rescue Errno::ECONNREFUSED => exception
      return oops :ended, exception, "conn_refused"

    rescue Timeout::Error, Errno::ETIMEDOUT, Net::ReadTimeout => exception
      return oops :ended, exception, "conn_timed_out"

    rescue OpenSSL::SSL::SSLError => exception
      return oops :ended, exception, "conn_openssl_error"

    rescue Net::FTPReplyError => exception
      return oops :ended, exception, "ftp_reply_error"

    rescue Net::FTPTempError => exception
      return oops :ended, exception, "ftp_temp_error"

    rescue Net::FTPPermError => exception
      return oops :ended, exception, "ftp_perm_error"

    rescue Net::FTPProtoError => exception
      return oops :ended, exception, "ftp_proto_error"

    rescue Net::FTPError => exception
      return oops :ended, exception, "ftp_error"

    rescue Net::SFTP::StatusException => exception
      return oops :ended, exception, "sftp_exception"

    rescue Net::SSH::HostKeyMismatch => exception
      return oops :ended, exception, "sftp_key_mismatch"

    rescue Net::SSH::AuthenticationFailed => exception
      return oops :ended, exception, "sftp_auth_failed"

    rescue Errno::EMFILE => exception
      return oops :ended, exception, "too_many_open_files"

    rescue Errno::EINVAL => exception
      return oops :ended, exception, "invalid_argument", true

    # rescue Encoding::UndefinedConversionError => exception
    #   return oops :ended, exception, "encoding_error", true

    rescue RestFtpDaemon::SourceNotFound => exception
      return oops :ended, exception

    rescue RestFtpDaemon::TargetFileExists => exception
      return oops :ended, exception

    rescue RestFtpDaemon::TargetDirectoryError => exception
      return oops :ended, exception

    rescue RestFtpDaemon::TargetPermissionError => exception
      return oops :ended, exception

    rescue RestFtpDaemon::AssertionFailed => exception
      return oops :ended, exception
    end

    def after
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
      log_info "Job.remote_push [#{source.name}]: [#{source.full}] > [#{target.full}]"
      set_info :source, :current, source.name

      # Compute temp target name
      tempname = nil
      if @tempfile
        tempname = "#{target.name}.temp-#{identifier(JOB_TEMPFILE_LEN)}"
        log_debug "Job.remote_push tempname [#{tempname}]"
      end

      # Remove any existing version if expected, or test its presence
      if @overwrite
        @remote.remove! target
      elsif size = @remote.present?(target)
        log_debug "Job.remote_push existing (#{format_bytes size, 'B'})"
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
      set_info :transfer, :bitrate, global_transfer_bitrate.round(0)

      # Done
      set_info :source, :current, nil
    end

    def progress transferred, name = ""


      # What's current time ?
      now = Time.now
      notify_after = @config[:notify_after]

      # Update counters
      @transfer_sent += transferred
      set_info :transfer, :sent, @transfer_sent

      # Update job info
      percent0 = (100.0 * @transfer_sent / @transfer_total).round(0)
      set_info :transfer, :progress, percent0

      # Update job status after each NOTIFY_UPADE_STATUS
      progressed_ago = (now.to_f - @progress_at.to_f)
      if (!JOB_UPDATE_INTERVAL.to_f.zero?) && (progressed_ago > JOB_UPDATE_INTERVAL.to_f)
        @current_bitrate = running_bitrate @transfer_sent
        set_info :transfer, :bitrate, @current_bitrate.round(0)

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
