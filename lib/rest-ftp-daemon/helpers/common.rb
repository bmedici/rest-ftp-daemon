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

    def tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end

    def dashboard_url filter = ''
      "#{MOUNT_BOARD}/#{filter}"
    end

    # Dates and times: date with time generator
    # def datetime_full datetime
    #   return "-"  if datetime.nil?
    #   datetime.to_datetime.strftime("%d.%m.%Y %H:%M:%S")
    # end

  end
end
