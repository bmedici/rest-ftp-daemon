module Shared
  class LoggerFormatter

    def self.call severity, datetime, progname, payload
      # Build common values
      timestamp = datetime.strftime(LOG_HEADER_TIME)

      # Build header
      header = sprintf LOG_HEADER_FORMAT,
        timestamp,
        Process.pid,
        severity,
        progname

      # If we have a bunch of lines, prefix them and send them together
      return payload.map do |line|
        "#{header}#{trimmed(line)}\n"
      end.join if payload.is_a?(Array)

      # Otherwise, just prefix the only line
      return "#{header}#{trimmed(payload)}\n"
    end

  protected

    def self.trimmed line
      line.to_s.rstrip[0..LOG_MESSAGE_TRIM].force_encoding(Encoding::UTF_8)
    end

  end
end
