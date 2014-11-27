module RestFtpDaemon
  module API
    class Root < Grape::API


####### GET /routes

      get '/routes' do
        info "GET /routes"
        status 200
        return RestFtpDaemon::API::Root::routes
      end

    end
  end
end
