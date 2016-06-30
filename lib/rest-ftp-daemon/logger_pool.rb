require "logger"

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
      if (filename)
        puts "LoggerPool: logging [#{pipe}] to [#{filename}]"
      else
        puts "LoggerPool: logging disabled for [#{pipe}]"
      end

      # Create the logger and return it
      logger = Logger.new(filename, LOG_ROTATION)   #, 10, 1024000)
      logger.progname = pipe.to_s.downcase
      logger.formatter = Shared::LoggerFormatter

      # Finally return this logger
      logger
    end

  protected

    def logfile pipe
      # Disabled if no valid config
      return nil unless Conf[:logs].is_a?(Hash)

      # Compute logfile and check if we can write there
      #logfile = File.join(Conf[:logs][:path].to_s, Conf[:logs][pipe].to_s)
      logfile = File.expand_path(Conf[:logs][pipe], Conf[:logs][:path])
      # File.expand_path("#{Conf[:logs][:base]}/#{Conf[:logs][pipe]}")
      return nil if File.exists?(logfile) && !File.writable?(logfile)

      # OK, return a clean file path
      return logfile
    end


  end
end
