module RestFtpDaemon
  class Helpers

    def self.get_censored_config
      config = Settings.to_hash
      config[:users] = Settings.users.keys if Settings.users
      config[:endpoints] = Settings.endpoints.keys if Settings.endpoints
      config
    end

    def self.format_bytes number, unit="", decimals = 0
      return "&Oslash;" if number.nil? || number.to_f.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log( number ) / Math.log( 2 ) ).to_i / 10
      converted = number.to_f / ( 1024 ** index )

      truncated = converted.round(decimals)

      "#{truncated} #{units[index]}#{unit}"
    end

    def self.text_or_empty text
      return "-" if text.nil? || text.empty?

      text
    end

    def self.identifier len
      rand(36**len).to_s(36)
    end

    def self.tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end

    def self.highlight_tokens path
      return unless path.is_a? String
      path.gsub(/\[([^\[]+)\]/, '<span class="token">\1</span>')
    end

    def self.extract_filename path
      return unless path.is_a? String
      # match everything that's after a slash at the end of the string
      m = path.match(/\/?([^\/]+)$/)
      return m[1] unless m.nil?
    end

    def self.extract_dirname path
      return unless path.is_a? String
      # match all the beginning of the string up to the last slash
      m = path.match(/^(.*)\/[^\/]*$/)
      return "/#{m[1]}" unless m.nil?
    end

    def self.extract_parent path
      return unless path.is_a? String
      m = path.match(/^(.*)\/([^\/]+)\/?$/)
      return m[1], m[2] unless m.nil?
    end

    def self.local_port_used? port
      begin
        Timeout.timeout(BIND_PORT_TIMEOUT) do
          begin
            TCPSocket.new(BIND_PORT_LOCALHOST, port).close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          rescue Errno::EADDRNOTAVAIL
            "Settings.local_port_used: Errno::EADDRNOTAVAIL"
          end
        end
      rescue Timeout::Error
        false
      end
    end

    def self.job_method_label method
      return if method.nil?
      klass = case method
      when :file
        "label-primary"
      when :ftp
        "label-warning"
      when :ftps, :ftpes
        "label-success"
      else
        "label-default"
      end
      "<div class=\"transfer-method label #{klass}\">#{method.upcase}</div>"
    end

    # Dates and times: date with time generator
    def self.datetime_full datetime
      return "-"  if datetime.nil?

      datetime.to_datetime.strftime("%d.%m.%Y %H:%M:%S")
    end

    def self.datetime_short datetime
      # return param.class
      return "-" if datetime.nil?
      return "?" unless datetime.respond_to? :to_date
      return datetime.to_datetime.strftime("%H:%M:%S") if datetime.to_date == Time.now.to_date

      datetime.to_datetime.strftime("%d/%m %H:%M:%S")
    end

    def self.hide_credentials_from_url path
      return unless path.is_a? String
      path.sub(/([a-z]+:\/\/[^\/]+):[^\/]+\@/, '\1@' )
    end

    def self.formatted_duration duration
    out = []

    hours = duration / (60 * 60)
    minutes = (duration / 60) % 60
    seconds = duration % 60

    out << "#{hours}h" if hours>0
    out << "#{minutes}mn" if (minutes>0) || (hours>0)
    out << "#{seconds}s"

    out.join(' ')
  end

  end
end
