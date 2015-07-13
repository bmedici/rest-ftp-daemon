require "net/ftp"
require "double_bag_ftps"

module RestFtpDaemon
  class RemoteFTP < Remote
    attr_reader :ftp

    def initialize url, log_context, options = {}
      # Call super
      super

      # Use debug ?
      @debug = (Settings.at :debug, :ftp) == true

      # Create FTP object
      if options[:ftpes]
        prepare_ftpes
      else
        prepare_ftp
      end
      @ftp.passive = true
      @ftp.debug_mode = !!@debug

      # Config
      @chunk_size = DEFAULT_FTP_CHUNK.to_i * 1024

      # Announce object
      log_info "RemoteFTP.initialize chunk_size:#{@chunk_size}"
    end

    def connect
      # Connect init
      super

      # Connect remote server
      @ftp.connect @url.host, @url.port
      @ftp.login @url.user, @url.password
    end

    def present? target
      size = @ftp.size target.full
      log_info "RemoteFTP.present? [#{target.name}]"

      rescue Net::FTPPermError
        # log_info "RemoteFTP.present? [#{target.name}] NOT_FOUND"
        return false
      else
        return size
    end

    def remove! target
      log_info "RemoteFTP.remove! [#{target.name}]"
      @ftp.delete target.full
      rescue Net::FTPPermError
        log_info "#{LOG_INDENT}[#{target.name}] file not found"
      else
        log_info "#{LOG_INDENT}[#{target.name}] removed"
    end

    def mkdir directory
      log_info "RemoteFTP.mkdir [#{directory}]"
      @ftp.mkdir directory

      rescue
        raise JobTargetPermissionError
    end

    def chdir_or_create directory, mkdir = false
      # Init, extract my parent name and my own name
      log_info "RemoteFTP.chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
      parent, current = Helpers.extract_parent(directory)

      fulldir = "/#{directory}"

      # Access this directory
      begin
        @ftp.chdir "/#{directory}"

      rescue Net::FTPPermError => e
        # If not allowed to create path, that's over, we're stuck
        return false unless mkdir

        #log_info "#{LOG_INDENT}upward [#{parent}]"
        chdir_or_create parent, mkdir

        # Now I was able to chdir into my parent, create the current directory
        #log_info "#{LOG_INDENT}mkdir [#{directory}]"
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
      log_info "RemoteFTP.push to [#{destination.name}]"

      @ftp.putbinaryfile source.full, target.name, @chunk_size do |data|
        # Update the worker activity marker
        #FIXME worker_is_still_active

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
