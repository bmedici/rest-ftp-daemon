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



    def self.job_runs_style runs
      return  "label-outline"     if runs <= 0
      return  "label-info"  if runs == 1
      return  "label-warning"  if runs == 2
      return  "label-danger"   if runs > 2
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
      path.sub(/([a-z]+:\/\/[^\/]+):[^\/]+\@/, '\1@')
    end

    def self.formatted_duration duration
    out = []

    hours = duration / (60 * 60)
    minutes = (duration / 60) % 60
    seconds = duration % 60

    out << "#{hours}h" if hours > 0
    out << "#{minutes}mn" if (minutes > 0) || (hours > 0)
    out << "#{seconds}s"

    out.join(" ")
    end

    def self.dashboard_filter_url filter = ''
      "#{MOUNT_BOARD}/#{filter}"
    end

  end
end
