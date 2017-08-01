module RestFtpDaemon::Task
  class ExportError        < TaskError; end

  class TaskExport < TaskBase

    # Task statuses
    STATUS_CONNECTING    = "connect"
    STATUS_CHDIR         = "chdir"
    STATUS_UPLOADING     = "upload"
    STATUS_RENAMING      = "rename"
    STATUS_DISCONNECTING = "disconnect"

    # Task info
    def task_icon
      "arrow-up"
    end
    def task_name
      "export"
    end

    # Task operations
    def prepare stash
      # Check output target
      log_debug "prepare", {
        target_loc:     target_loc.to_s,
        flag_mkdir:     get_flag(:mkdir),
        flag_overwrite: get_flag(:overwrite),
        flag_tempfile:  get_flag(:tempfile),
        }

      # Guess target file name, and fail if present while we matched multiple sources
      if target_loc.name && stash.count > 1
        raise Task::TargetDirectoryError, "prepare: target should be a directory when severeal files matched"
      end

      # Some init
      @transfer_sent = 0

      # Detect plugin for this location
      @remote = Remote::RemoteBase.build(target_loc, @job, @config)
      unless @remote.is_a? Remote::RemoteBase
        raise Task::TargetUnsupported, "unknown scheme [#{target_loc.scheme}] [#{target_loc.uri.class.name}]"
      end
      log_info "handling [#{target_loc.scheme}] with #{@remote.class}"
    end

    def process stash
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

      # Do the transfer, for each file
        remote_upload input, get_flag(:tempfile), get_flag(:overwrite)
      stash.each do |name, input|
        @stash_processed += 1
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
    def init_config
      @config = Conf.at(:transfer)
    end

      # Method assertions
      raise Task::AssertionFailed, "remote_upload/remote" if @remote.nil?
      raise Task::AssertionFailed, "remote_upload/source" if source.nil?

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
        raise Task::TargetFileExists
      end

      # Start transfer
      transfer_started_at = Time.now
      @last_notify_at = transfer_started_at
      progress_update destination.name, 0

      # Start the transfer, update job status after each block transfer
      set_status STATUS_UPLOADING
      @remote.upload source, destination do |transferred|
        progress_update destination.name, transferred
      end

      # Transfer finished
      transfer_finished_at = Time.now
      transfer_lasted = transfer_finished_at - transfer_started_at

      # Explicitely send a 100% notification
      progress_finished destination.name, transfer_lasted

      # Rename file to target name
      if tempfile
        log_info "remote_upload: rename [#{destination.name}] > [#{target.name}]"
        @remote.move destination, target
      end

      # Update counters
      set_info INFO_TARGET_FILES, @output.collect(&:name)
      set_info INFO_CURRENT, nil
    end    

  end
end
