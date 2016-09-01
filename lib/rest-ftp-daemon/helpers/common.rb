module RestFtpDaemon
  module CommonHelpers

    def format_bytes number, unit="", decimals = 0
      return "&Oslash;" if number.nil? || number.to_f.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log(number) / Math.log(2) ).to_i / 10
      converted = number.to_f / (1024 ** index)

      truncated = converted.round(decimals)

      "#{truncated} #{units[index]}#{unit}"
    end

    def identifier len
      rand(36**len).to_s(36)
    end

    def dashboard_url filter = ''
      "#{MOUNT_BOARD}/#{filter}"
    end

    def underscore camel_cased_word
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def exception_to_error exception
      underscore 'err_' + exception.class.name.split('::').last
    end

  end
end
