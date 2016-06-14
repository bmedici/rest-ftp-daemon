module RestFtpDaemon
  module API
    class Config < Grape::API

      desc "Show daemon config"
      get "/" do
        status 200
        return Helpers.get_censored_config
      end

      desc "Reload daemon config"
      post "/reload" do
        if Conf.at(:debug, :allow_reload)==true
          Conf.reload!
          status 200
          return Helpers.get_censored_config
        else
          status 403
          return "Config reload not permitted"
        end
      end

    end
  end
end
