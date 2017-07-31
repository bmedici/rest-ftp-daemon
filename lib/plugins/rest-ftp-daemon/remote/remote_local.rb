# Dependencies

# Register this handler
module URI
  class FILE < Generic; end
  @@schemes["FILE"]   = FILE
end

# Handle FTP and FTPES transfers for Remote class
module RestFtpDaemon::Remote
  class RemoteLocal < RemoteBase
      # URI schemes handled by this plugin
      def self.handles
        [URI::FILE]
      end

      def size_if_exists target
        log_debug "size_if_exists [#{target.name}]"
        return false unless File.exist? target.path_abs
        return File.size target
      end

      def remote_try_delete target
        File.delete target.path_abs
      rescue Errno::ENOENT
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
        # Init
        log_debug "chdir_or_create mkdir[#{mkdir}] dir[#{thedir}]"

        # Access this directory
        begin
          FileUtils.chdir thedir       

        rescue Errno::ENOENT
          # Create the missing directory
          FileUtils.mkdir_p thedir

          # Finally retry the chdir
          retry
        else
          return true
        end

      end

      def upload source, target, &callback
        # Do the transfer
        copy source, target
      end

      def move source, target
        log_debug "move [#{source.name}] > [#{target.name}]"
        FileUtils.move source.path_abs, target.path_abs
      end

      def copy source, target
        log_debug "copy [#{source.name}] > [#{target.name}]"
        FileUtils.copy_file source.path_abs, target.path_abs
      end

    private

      def debug_enabled
        @config[:debug_file]
      end

  end
end