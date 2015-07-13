require "net/sftp"

module RestFtpDaemon
  class RemoteSFTP < Remote
    attr_reader :sftp

    def initialize url, log_context, options = {}
      # Call super
      super

      # Use debug ?
      @debug = (Settings.at :debug, :sftp) == true

      # Announce object
      log_info "RemoteSFTP.initialize"
    end

    def connect
      # Connect init
      super
      log_info "RemoteSFTP.connect [#{@url.user}]@[#{@url.host}]:[#{@url.port}]"

      # Debug level
      verbosity = @debug ? Logger::INFO : false

      # Connect remote server
      @sftp = Net::SFTP.start(@url.host, @url.user, password: @url.password, verbose: verbosity, port: @url.port)
    end

    def present? target
      log_info "RemoteSFTP.present? [#{target.name}]"
      stat = @sftp.stat! target.full
      size = "?"

      rescue Net::SFTP::StatusException
        return false
      else
        return stat.size
    end

    # def remove target
    #   log_info "RemoteSFTP.remove [#{target.name}]"
    #   @sftp.remove target.full
    # end

    def remove! target
      log_info "RemoteSFTP.remove! [#{target.name}]"
      @sftp.remove target.full

      rescue Net::SFTP::StatusException
        log_info "#{LOG_INDENT}[#{target.name}] file not found"
      else
        log_info "#{LOG_INDENT}[#{target.name}] removed"
    end

    def mkdir directory
      log_info "RemoteSFTP.mkdir [#{directory}]"
      @sftp.mkdir! directory

      rescue
        raise JobTargetPermissionError
    end

    def chdir_or_create directory, mkdir = false
      # Init, extract my parent name and my own name
      log_info "RemoteSFTP.chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
      parent, current = Helpers.extract_parent(directory)

      # Access this directory
      begin
        # log_info "   chdir [/#{directory}]"
        handle = @sftp.opendir! "./#{directory}"

      rescue Net::SFTP::StatusException => e
        # If not allowed to create path, that's over, we're stuck
        return false unless mkdir

        # Recurse upward
        #log_info "#{LOG_INDENT}upward [#{parent}]"
        chdir_or_create parent, mkdir

        # Now I was able to chdir into my parent, create the current directory
        #log_info "#{LOG_INDENT}mkdir [#{directory}]"
        mkdir directory

        # Finally retry the chdir
        retry
      else
        return true
      end

      # We should never get here
      raise JobTargetShouldBeDirectory
    end

    # def dir_contents directory
    #   # Access this directory
    #   handle = @sftp.opendir! directory
    #   @sftp.readdir! handle
    # end

    def push source, target, tempname = nil, &callback
      # Push init
      raise RestFtpDaemon::JobAssertionFailed, "push/1" if @sftp.nil?

      # Temp file if provided
      destination = target.clone
      destination.name = tempname if tempname

      # Do the transfer
      log_info "RemoteSFTP.push [#{destination.full}]"
      @sftp.upload! source.full, destination.full do |event, uploader, *args|
        case event
        when :open then
          # args[0] : file metadata
        when :put then
          # args[0] : file metadata
          # args[1] : byte offset in remote file
          # args[2] : data being written (as string)
          # puts "writing #{args[2].length} bytes to #{args[0].remote} starting at #{args[1]}"

          # Update the worker activity marker
          #FIXME worker_is_still_active

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
        log_info "RemoteSFTP.push rename to\t[#{target.name}]"
        @sftp.rename! destination.full, target.full, flags
      end

      # progress:
      # Net::SFTP::StatusException
    end

    def close
      # Close init
      super

      # @sftp.close
    end

    def connected?
      @sftp && !@sftp.closed?
    end

  end
end
