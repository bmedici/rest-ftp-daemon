require "net/ftp"
require "double_bag_ftps"

module RestFtpDaemon
  # Handles FTP and FTPeS transfers for Remote class
  class RemoteFTP < Remote
    attr_reader :ftp

    def initialize url, log_prefix, options = {}
      # Call super
      super

      # Create FTP object
      if options[:ftpes]
        prepare_ftpes
      else
        prepare_ftp
      end
      @ftp.passive = true
      @ftp.debug_mode =  @debug

      # Config
      @chunk_size = DEFAULT_FTP_CHUNK.to_i * 1024

      # Announce object
      log_debug "RemoteFTP.initialize chunk_size:#{@chunk_size}"
    end

    def connect
      # Connect remote server
      super
      @ftp.connect @url.host, @url.port
      @ftp.login @url.user, @url.password
    end

    def present? target
      size = @ftp.size target.full
      log_debug "RemoteFTP.present? [#{target.name}]"

    rescue Net::FTPPermError
      return false
    else
      return size
    end

    def remove! target
      log_debug "RemoteFTP.remove! [#{target.name}]"
      @ftp.delete target.full
    rescue Net::FTPPermError
      log_debug "#{LOG_INDENT}[#{target.name}] file not found"
    else
      log_debug "#{LOG_INDENT}[#{target.name}] removed"
    end

    def mkdir directory
      log_debug "RemoteFTP.mkdir [#{directory}]"
      @ftp.mkdir directory

      rescue
        raise JobTargetPermissionError
    end

    def chdir_or_create directory, mkdir = false
      # Init, extract my parent name and my own name
      log_debug "RemoteFTP.chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
      parent, _current = Helpers.extract_parent(directory)

      # Access this directory
      begin
        @ftp.chdir "/#{directory}"

      rescue Net::FTPPermError => _e
        # If not allowed to create path, that's over, we're stuck
        return false unless mkdir
        chdir_or_create parent, mkdir

        # Now I was able to chdir into my parent, create the current directory
        mkdir "/#{directory}"

        # Finally retry the chdir
        retry
      else
        return true
      end
    end

    def push source, target, tempname = nil, &callback
      # Push init
      raise RestFtpDaemon::JobAssertionFailed, "push/1" if @ftp.nil?

      # Temp file if provided
      destination = target.clone
      destination.name = tempname if tempname

      # Do the transfer
      log_debug "RemoteFTP.push to [#{destination.name}]"

      @ftp.putbinaryfile source.full, target.name, @chunk_size do |data|
        # Update job status after this block transfer
        yield data.bytesize, destination.name
      end
    end

    def close
      # Close init
      super

      # Close FTP connexion and free up memory
      @ftp.close
    end

    def connected?
      !@ftp.welcome.nil?
    end

  private

    def prepare_ftp
      @ftp = Net::FTP.new
    end

    def prepare_ftpes
      @ftp = DoubleBagFTPS.new
      @ftp.ssl_context = DoubleBagFTPS.create_ssl_context(verify_mode: OpenSSL::SSL::VERIFY_NONE)
      @ftp.ftps_mode = DoubleBagFTPS::EXPLICIT
    end

  end
end
