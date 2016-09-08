require "net/ftp"
require "double_bag_ftps"

# Handle FTP and FTPES transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteFTP < RemoteBase

      # Class options
      attr_reader :ftp

      def prepare
        # Create FTP object
        if @ftpes
          prepare_ftpes
        else
          prepare_ftp
        end
        @ftp.passive = true
        @ftp.debug_mode = @debug

        # Config
        @chunk_size = JOB_FTP_CHUNKMB.to_i * 1024

        # Announce object
        log_debug "Remote::RemoteFTP.prepare chunk_size:#{@chunk_size}"
      end

      def connect
        super

        # Connect remote server
        @ftp.connect @target.host, @target.port
        @ftp.login @target.user, @target.password
      end

      def present? target
        size = @ftp.size target.path
        log_debug "Remote::RemoteFTP.present? [#{target.name}]"

      rescue Net::FTPPermError
        return false
      else
        return size
      end

      def remove! target
        @ftp.delete target.path
      rescue Net::FTPPermError
        log_debug "Remote::RemoteFTP.remove! [#{target.name}] not found"
      else
        log_debug "Remote::RemoteFTP.remove! [#{target.name}] removed"
      end

      def mkdir directory
        log_debug "Remote::RemoteFTP.mkdir [#{directory}]"
        @ftp.mkdir directory

      rescue StandardError => ex
        raise TargetPermissionError, ex.message
      end

      def chdir_or_create directory, mkdir = false
        # Init, extract my parent name and my own name
        log_debug "Remote::RemoteFTP.chdir_or_create mkdir[#{mkdir}] dir[#{directory}]"
        parent, current = extract_parent(directory)

        #dirname, _current = extract_parent(directory)


        # Access this directory
        begin
          @ftp.chdir "/#{directory}"

        rescue Net::FTPPermError => _e
          # If not allowed to create path, that's over, we're stuck
          return false unless mkdir
          chdir_or_create parent, mkdir

          # Now I was able to chdir into my parent, create the current directory
          mkdir current

          # Finally retry the chdir
          retry
        else
          return true
        end
      end

      def upload source, target, use_temp_name = false, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "upload/ftp" if @ftp.nil?

        # Temp file if needed
        dest = target.clone
        if use_temp_name
          dest.generate_temp_name!
        end

        # Move to the directory
        log_debug "Remote::RemoteFTP.upload chdir [#{dest.dir}]"
        @ftp.chdir "/#{dest.dir}"

        # Do the transfer
        log_debug "Remote::RemoteFTP.upload putbinaryfile [#{dest.name}]"
        @ftp.putbinaryfile source.path, dest.name, @chunk_size do |data|
          # Update job status after this block transfer
          yield data.bytesize, dest.name
        end

        # Move the file back to its original name
        if use_temp_name
          log_debug "Remote::RemoteFTP.upload rename [#{dest.name}] > [#{target.name}]"
          @ftp.rename dest.name, target.name
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
end
