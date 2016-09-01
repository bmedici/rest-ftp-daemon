require "net/sftp"

# Handle sFTP transfers for Remote class
module RestFtpDaemon
  class RemoteSFTP < Remote

    # Class options
    attr_reader :sftp

    def prepare
    end

    def connect
      # Connect init
      super
      log_debug "RemoteSFTP.connect [#{@target.user}]@[#{@target.host}]:[#{@target.port}]"

      # Debug level
      verbosity =  @debug ? Logger::DEBUG : false

      # Connect remote server
      @sftp = Net::SFTP.start(@target.host.to_s, @target.user.to_s,
          password: @target.password.to_s,
          verbose: verbosity,
          port: @target.port,
          non_interactive: true,
          timeout: DEFAULT_SFTP_TIMEOUT
          )
    end

    def present? target
      log_debug "RemoteSFTP.present? [#{target.name}]"
      stat = @sftp.stat! target.path

    rescue Net::SFTP::StatusException
      return false
    else
      return stat.size
    end

    def remove! target
      log_debug "RemoteSFTP.remove! [#{target.name}]"
      @sftp.remove target.path

    rescue Net::SFTP::StatusException
      log_debug "#{LOG_INDENT}[#{target.name}] file not found"
    else
      log_debug "#{LOG_INDENT}[#{target.name}] removed"
    end

    def mkdir directory
      log_debug "RemoteSFTP.mkdir [#{directory}]"
      @sftp.mkdir! directory

      rescue
        raise TargetPermissionError
    end

    def chdir_or_create directory, mkdir = false
      # Init, extract my parent name and my own name
      log_debug "RemoteSFTP.chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
      parent, _current = extract_parent(directory)

      # Access this directory
      begin
        log_debug "chdir [/#{directory}]"
        @sftp.opendir! "./#{directory}"

      rescue Net::SFTP::StatusException => _e
        # If not allowed to create path, that's over, we're stuck
        return false unless mkdir

        # Recurse upward
        chdir_or_create parent, mkdir

        # Now I was able to chdir into my parent, create the current directory
        mkdir directory

        # Finally retry the chdir
        retry
      else
        return true
      end

      # We should never get here
      raise JobTargetShouldBeDirectory
    end

    def upload source, target, use_temp_name = false, &callback
      # Push init
      raise RestFtpDaemon::AssertionFailed, "push/sftp" if @sftp.nil?

      # Temp file if provided
      destination = target.clone
      destination.name = tempname if tempname

      # Do the transfer
      log_debug "RemoteSFTP.push [#{destination.path}]"
      @sftp.upload! source.path, destination.path do |event, _uploader, *args|
        case event
        when :open then
          # args[0] : file metadata
        when :put then
          # args[0] : file metadata
          # args[1] : byte offset in remote file
          # args[2] : data being written (as string)
          # puts "writing #{args[2].length} bytes to #{args[0].remote} starting at #{args[1]}"

          # Update job status after this block transfer
          yield args[2].length, destination.name

        when :close then
          # args[0] : file metadata
        when :mkdir
          # args[0] : remote path name
        when :finish
        end

      end

      # flags = 0x0001 + 0x0002
      flags = 0x00000001

      # Rename if needed
      if tempname
        log_debug "RemoteSFTP.push rename to\t[#{target.name}]"
        @sftp.rename! destination.path, target.path, flags
      end

      # progress:
      # Net::SFTP::StatusException
    end

    def close
      # Close init
      super
    end

    def connected?
      @sftp && !@sftp.closed?
    end

  end
end
