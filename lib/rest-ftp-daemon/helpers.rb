require 'securerandom'

module RestFtpDaemon
  class Helpers

    def self.get_censored_config
      config = Settings.to_hash
      config[:users] = Settings.users.keys if Settings.users
      config[:endpoints] = Settings.endpoints.keys if Settings.endpoints
      config
    end

    def self.format_bytes number, unit=""
      return "&Oslash;" if number.nil? || number.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log( number ) / Math.log( 2 ) ).to_i / 10
      converted = number.to_i / ( 1024 ** index )
      "#{converted} #{units[index]}#{unit}"
    end

    def self.text_or_empty text
      return "&Oslash;" if text.nil? || text.empty?
      text
    end

    def self.identifier len
      rand(36**len).to_s(36)
    end

    def self.tokenize(item)
      "[#{item}]"
    end

    def self.highlight_tokens(path)
      path.gsub(/(\[[^\[]+\])/, '<span class="token">\1</span>')
    end

    def self.extract_filename path
      # match everything that's after a slash at the end of the string
      m = path.match /\/?([^\/]+)$/
      return m[1] unless m.nil?
    end

    def self.extract_dirname path
      # match all the beginning of the string up to the last slash
      m = path.match(/^(.*)\/[^\/]*$/)
      return "/#{m[1]}" unless m.nil?
    end

    def self.extract_parent path
      # m = path.match(/^(.*\/)[^\/]*\/+$/)
      m = path.match(/^(.*\/)[^\/]+\/?$/)
      return m[1] unless m.nil?
    end

    def self.local_port_used? port
      ip = '0.0.0.0'
      timeout = 1
      begin
        Timeout::timeout(timeout) do
          begin
            TCPSocket.new(ip, port).close
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
        'label-primary'
      when :ftp
        'label-danger'
      when :ftps
        'label-warning'
      when :ftpes
        'label-warning'
      else
         'label-default'
      end
      "<div class=\"transfer-method label #{klass}\">#{method.upcase}</div>"
    end

    # Dates and times: date with time generator
    def self.datetime_full param
      return "-"  if param.nil?
      return param.to_datetime.strftime("%d.%m.%Y %H:%M")
    end

    def self.datetime_short param
      return "-"  if param.nil?
      return param.to_datetime.strftime("%d/%m %H:%M")
    end

  end
end
