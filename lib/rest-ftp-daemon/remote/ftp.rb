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
        log_debug "RemoteFTP.prepare chunk_size:#{@chunk_size}"
      end

      def connect
        super

        # Connect remote server
        @ftp.connect @target.host, @target.port
        @ftp.login @target.user, @target.password
      end

      def size_if_exists target
        size = @ftp.size target.filepath
        log_debug "size_if_exists [#{target.name}]"

      rescue Net::FTPPermError
        return false
      else
        return size
      end

      def remove! target
        @ftp.delete target.filepath
      rescue Net::FTPPermError
        log_debug "remove! [#{target.name}] not found"
      else
        log_debug "remove! [#{target.name}] removed"
      end

      def mkdir directory
        log_debug "mkdir [#{directory}]"
        @ftp.mkdir directory

      rescue StandardError => ex
        raise TargetPermissionError, ex.message
      end

      def chdir_or_create thedir, mkdir = true
        # Init, extract my parent name and my own name
        parent, current = split_path(thedir)
        log_debug "chdir_or_create mkdir[#{mkdir}] dir[#{thedir}] parent[#{parent}] current[#{current}]"

        # Access this directory
        begin
          @ftp.chdir "/#{thedir}"

        rescue Net::FTPPermError => _e

          # If not allowed to create path, that's over, we're stuck
          unless mkdir
            log_debug "  [#{thedir}] failed > no mkdir > over"
            return false
          end

          # Try to go into my parent directory
          log_debug "  [#{thedir}] failed > chdir_or_create [#{parent}]"
          chdir_or_create parent, mkdir

          # Now I was able to chdir into my parent, create the current directory
          log_debug "  [#{thedir}] failed > mkdir [#{current}]"
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
        log_debug "upload chdir [#{dest.filedir}]"
        @ftp.chdir dest.filedir

        # Do the transfer
        log_debug "RemoteFTP.upload putbinaryfile [#{dest.name}]"
        @ftp.putbinaryfile source.filepath, dest.name, @chunk_size do |data|
          # Update job status after this block transfer
          yield data.bytesize, dest.name
        end

        # Move the file back to its original name
        if use_temp_name
          log_debug "upload rename [#{dest.name}] > [#{target.name}]"
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