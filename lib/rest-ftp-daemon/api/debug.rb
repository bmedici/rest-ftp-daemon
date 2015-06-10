module RestFtpDaemon
  module API
    class Root < Grape::API

####### GET /debug

      get "/raise" do
        log_info "GET /debug"
        begin
          raise RestFtpDaemon::DummyException
        rescue RestFtpDaemon::RestFtpDaemonException => exception
          status 501
          api_error exception
        rescue StandardError => exception
          status 501
          api_error exception
        else
          status 200
          {}
        end
      end

      get "/routes" do
        log_info "GET /routes"
        status 200
        return RestFtpDaemon::API::Root.routes
      end

    end
  end
end
