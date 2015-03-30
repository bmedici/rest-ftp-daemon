module RestFtpDaemon
  module API
    class Root < Grape::API

####### GET /debug

      get '/raise' do
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

      # get '/memsize' do
      #   info "GET /memsize"
      #   ObjectSpace.each_object do |e|
      #     #puts
      #     print ObjectSpace.memsize_of(e)
      #     print "\t"
      #     print e.class.to_s
      #     print "\t"
      #     puts e.inspect[0..80]
      #     # puts ({
      #     #   klass: e.class,
      #     #   size: ObjectSpace.memsize_of(e),
      #     # }.inspect)
      #     # puts
      #   end
      #   status 200
      #   []
      # end

    end
  end
end
