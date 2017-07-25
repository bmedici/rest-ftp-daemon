# Dependencies
require "net/ftp"

# Register this handler
module URI
  class FILE < Generic; end
  class FTPS < Generic; end
  class FTPES < Generic; end
  @@schemes["FILE"]   = FILE
  @@schemes["FTPS"]   = FTPS
  @@schemes["FTPES"]  = FTPES
end


# Handle FTP and FTPES transfers for Remote class
module RestFtpDaemon::Remote
  class RemoteFTP < Base

      # Defaults
      FTP_CHUNK_MB         = 2*MB

      # Class options
      attr_reader :ftp

      def initialize target, job, config
        super

        # Create FTP object
        if @target.secure?
          prepare_ftpes
        else
          prepare_ftp
        end
        @ftp.passive = true
        @ftp.debug_mode = debug_enabled

        # Announce object
        log_debug "prepare chunk_size:#{format_bytes(FTP_CHUNK_MB, "B")}"
      end

      def connect
        super

        # Connect remote server
        @ftp.connect @target.host, @target.port
        @ftp.login @target.user, @target.password

      rescue Exception => exception
        raise RemoteConnectError, "#{exception.class}: #{exception.message}"
      end

      def connected?
        !@ftp.welcome.nil?
      end

      def close
        log_debug "remote close"
        @ftp.close if connected?
      end

      def size_if_exists target
        log_debug "size_if_exists [#{target.name}]"
        size = @ftp.size target.path_abs

      rescue Net::FTPPermError
        return false
      else
        return size
      end

      def remote_try_delete target
        @ftp.delete target.path_abs
      rescue Net::FTPPermError
        log_debug "remote_try_delete [#{target.name}] not found"
      else
        log_debug "remote_try_delete [#{target.name}] removed"
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
        absdir = "/#{thedir}"

        # Access this directory
        begin
          @ftp.chdir absdir

        rescue Net::FTPPermError => _e

          # If not allowed to create path, that's over, we're stuck
          unless mkdir
            log_debug "  [#{absdir}] failed > no mkdir > over"
            return false
          end

          # Try to go into my parent directory
          log_debug "  [#{absdir}] failed > chdir_or_create [#{parent}]"
          chdir_or_create parent, mkdir

          # Now I was able to chdir into my parent, create the current directory
          log_debug "  [#{absdir}] failed > mkdir [#{current}]"
          mkdir current

          # Finally retry the chdir
          retry
        else
          log_debug "  [#{absdir}] cd successful"
          return true
        end

      end

      def push source, target, &callback
        # Push init
        raise RestFtpDaemon::AssertionFailed, "push/ftp" if @ftp.nil?

        # Move to the directory
        #log_debug "chdir [#{target.dir_abs}]"
        # @ftp.chdir target.dir_abs

        # Do the transfer
        log_debug "putbinaryfile abs[#{source.path_abs}] [#{target.name}]"
        @ftp.putbinaryfile source.path_abs, target.name, FTP_CHUNK_MB do |data|
          # Update job status after this block transfer
          yield data.bytesize, target.name
        end
      end

      def move source, target
        log_debug "move [#{source.name}] > [#{target.name}]"
        @ftp.rename source.name, target.name
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

      def debug_enabled
        @config[:debug_ftp]
      end

  end
end