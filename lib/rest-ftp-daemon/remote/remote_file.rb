require "net/ftp"
require "double_bag_ftps"

# Handle FTP and FTPES transfers for Remote class
module RestFtpDaemon
  module Remote
    class RemoteFile < RemoteBase

      def size_if_exists target
        log_debug "size_if_exists [#{target.name}]"
        return false unless File.exist? target
        return File.size target
      end

      def remove! target
        File.delete target.path
      rescue Errno::ENOENT
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
        FileUtils.copy_file source.path, target.path
      end

      def move source, target
        log_debug "move [#{source.name}] > [#{target.name}]"
        FileUtils.move source.path, target.path
      end

      # def connected?
      #   !@ftp.welcome.nil?
      # end

    end
  end
end