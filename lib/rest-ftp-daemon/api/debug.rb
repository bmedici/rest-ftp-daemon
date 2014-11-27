module RestFtpDaemon
  module API
    class Root < Grape::API

####### GET /debug

      get '/debug' do
        info "GET /debug"
        begin
          raise RestFtpDaemon::DummyException
        rescue RestFtpDaemon::RestFtpDaemonException => exception
          status 501
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 200
          {}
        end
      end

    end
  end
end
