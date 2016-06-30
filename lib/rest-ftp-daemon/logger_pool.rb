require "logger"
require "singleton"

# Logger interface class to access logger though symbolic names
module RestFtpDaemon
  class LoggerPool
    include Singleton

    def get pipe
      @loggers ||= {}
      @loggers[pipe] ||= create(pipe)
    end

    def create pipe
      # Compute logfile or STDERR, and declare what we're doing
      filename = logfile(pipe)

      # Create the logger and return it
      logger = Logger.new(filename, LOG_ROTATION)   #, 10, 1024000)
      logger.progname = pipe.to_s.downcase
      logger.formatter = Shared::LoggerFormatter

      # Finally return this logger
      logger

    rescue Errno::EACCES
      puts "LoggerPool [#{pipe}] failed: access error"
    end

  protected

    def logfile pipe
      # Disabled if no valid config
      return nil unless Conf[:logs].is_a?(Hash)

      # Compute logfile and check if we can write there
      logfile = File.expand_path(Conf[:logs][pipe], Conf[:logs][:path])

      # Check that we'll be able to create logfiles
      if File.exists?(logfile)
        # File is there, is it writable ?
        unless File.writable?(logfile)
          puts "LoggerPool [#{pipe}] disabled: file not writable [#{logfile}]"
          return nil
        end
      else
        # No file here, can we create it ?
        logdir = File.dirname(logfile)
        unless File.writable?(logdir)
          puts "LoggerPool [#{pipe}] disabled: directory not writable [#{logdir}]"
          return nil
        end
      end

      # OK, return a clean file path
      puts "LoggerPool [#{pipe}] logging to [#{logfile}]"
      return logfile
    end

  end
end
