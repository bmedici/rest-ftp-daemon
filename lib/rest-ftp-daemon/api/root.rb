module RestFtpDaemon
  module API
    class Root < Grape::API


####### CLASS CONFIG

      helpers RestFtpDaemon::LoggerHelper

      logger RestFtpDaemon::LoggerPool.instance.get :api

      do_not_route_head!
      do_not_route_options!

      format :json


####### INITIALIZATION

      def initialize
        # Call daddy
        super

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingQueue unless defined? $pool
      end


####### HELPERS

      helpers do

        def logger
          Root.logger
        end

        def api_error exception
          {
          error: exception.message
          #:message => exception.backtrace.first,
          }
        end

        def render name, values={}
          template = File.read("#{APP_LIBS}/views/#{name}.haml")
          haml_engine = Haml::Engine.new(template)
          haml_engine.render(binding, values)
        end

      end

    end
  end
end
