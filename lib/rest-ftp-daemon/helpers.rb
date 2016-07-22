module RestFtpDaemon
  class Helpers

    def self.get_censored_config
      config = Conf.to_hash
      config[:users] = Conf[:users].keys if Conf[:users]
      config[:endpoints] = Conf[:endpoints].keys if Conf[:endpoints]
      config
    end

    def self.format_bytes number, unit="", decimals = 0
      return "&Oslash;" if number.nil? || number.to_f.zero?

      units = ["", "k", "M", "G", "T", "P" ]
      index = ( Math.log(number) / Math.log(2) ).to_i / 10
      converted = number.to_f / (1024 ** index)

      truncated = converted.round(decimals)

      "#{truncated} #{units[index]}#{unit}"
    end

    def self.identifier len
      rand(36**len).to_s(36)
    end

    def self.tokenize item
      return unless item.is_a? String
      "[#{item}]"
    end

    def self.job_runs_style runs
      return  "label-outline"     if runs <= 0
      return  "label-info"  if runs == 1
      return  "label-warning"  if runs == 2
      return  "label-danger"   if runs > 2
    end

    def self.datetime_short datetime
      # return param.class
      return "-" if datetime.nil?
      return "?" unless datetime.respond_to? :to_date
      return datetime.to_datetime.strftime("%H:%M:%S") if datetime.to_date == Time.now.to_date

      datetime.to_datetime.strftime("%d/%m %H:%M:%S")
    end


    # Dates and times: date with time generator
    # def datetime_full datetime
    #   return "-"  if datetime.nil?
    #   datetime.to_datetime.strftime("%d.%m.%Y %H:%M:%S")
    # end

  end
end
