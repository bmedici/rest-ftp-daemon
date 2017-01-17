module RestFtpDaemon
  module TransferHelpers

    def remote_upload source, target
      # Method assertions
      raise RestFtpDaemon::AssertionFailed, "remote_upload/remote" if @remote.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/source" if source.nil?
      raise RestFtpDaemon::AssertionFailed, "remote_upload/target" if target.nil?

      # Use source filename if target path provided none (typically with multiple sources)
      log_info "remote_upload temp[#{@tempfile}] source[#{source.path_fs}] target[#{target.path}]"
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
      log_info "progress #{stack2} \t#{name}"

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
end