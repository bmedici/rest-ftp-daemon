module RestFtpDaemon
  module HelpApis

    def get_censored_config
      config = Conf.to_hash
      config[:users] = Conf[:users].keys if Conf[:users]
      config[:endpoints] = Conf[:endpoints].keys if Conf[:endpoints]
      config
    end

  end
end
