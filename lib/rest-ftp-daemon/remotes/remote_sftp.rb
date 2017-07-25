# Dependencies
require "net/sftp"
require "rbnacl"
require "bcrypt_pbkdf"

# Register this handler
module URI
  class SFTP < Generic
    DEFAULT_PORT = 22
  end
  @@schemes["SFTP"]   = SFTP
end

# Handle sFTP transfers for Remote class
module RestFtpDaemon::Remote
  class RemoteSFTP < RemoteBase

    # Class options
    attr_reader :sftp

    # URI schemes handled by this plugin
    def self.handles
      [URI::SFTP]
    end

    def initialize target, job, config
      # Call daddy's initialize() first
      super
    end

    def connect
      super

      # Debug level
      if debug_enabled
        verbosity = Logger::DEBUG 
      else
        verbosity = false
      end

      # Connect remote server
      @sftp = Net::SFTP.start(@target.host.to_s, @target.user.to_s,
          password: @target.password.to_s,
          verbose: verbosity,
          port: @target.port,
          non_interactive: true,
          timeout: DEFAULT_SFTP_TIMEOUT
          )
    # rescue NotImplementedError => exception
    #   raise RemoteConnectError, "RemoteConnectError: #{exception.class}: #{exception.message}"

    rescue Exception => exception
      raise RemoteConnectError, "#{exception.class}: #{exception.message}"
    end

    def size_if_exists target
      log_debug "size_if_exists [#{target.name}]"
      stat = @sftp.stat! target.path_abs

    rescue Net::SFTP::StatusException
      return false
    else
      return stat.size
    end

    def remote_try_delete target
      log_debug "remote_try_delete [#{target.name}]"
      @sftp.remove target.path_abs

    rescue Net::SFTP::StatusException
      log_debug "#{LOG_INDENT}[#{target.name}] file not found"
    else
      log_debug "#{LOG_INDENT}[#{target.name}] removed"
    end

    def mkdir directory
      log_debug "mkdir [#{directory}]"
      @sftp.mkdir! directory

      rescue StandardError => ex
        raise TargetPermissionError, ex.message
    end

    def chdir_or_create directory, mkdir = false
      # Init, extract my parent name and my own name
      log_debug "chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
      parent, _current = split_path(directory)

      # Access this directory
      begin
        @sftp.opendir! directory

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

    def push source, target, &callback
      # Push init
      raise RestFtpDaemon::AssertionFailed, "push/sftp" if @sftp.nil?

      # Do the transfer
      @sftp.upload! source.path_abs, target.path_abs do |event, _uploader, *args|
        case event
        when :open then
          # args[0] : file metadata
        when :put then
          # args[0] : file metadata
          # args[1] : byte offset in remote file
          # args[2] : data being written (as string)
          # puts "writing #{args[2].length} bytes to #{args[0].remote} starting at #{args[1]}"

          # Update job status after this block transfer
          yield args[2].length, target.name

        when :close then
          # args[0] : file metadata
        when :mkdir
          # args[0] : remote path name
        when :finish
        end

      end
    end

    def move source, target
      @sftp.rename! source.path_abs, target.path_abs, 0x00000001
    end

    def close
      log_debug "remote close"
    end

    def connected?
      @sftp && !@sftp.closed?
    end
  
    def debug_enabled
      @config[:debug_sftp]
    end

  end
end