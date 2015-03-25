module RestFtpDaemon
  module API
    class Root < Grape::API


####### CLASS CONFIG

      # logger RestFtpDaemon::Logger.new(:api, "API")
      logger RestFtpDaemon::LoggerPool.instance.get :api

      do_not_route_head!
      do_not_route_options!

      # FIXME
      # add_swagger_documentation
      # default_error_formatter :json
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

        def info message, lines = []
          Root.logger.info_with_id message,
            lines: lines,
            origin: self.class.to_s
        end

        def api_error exception
          {
          :error => exception.message,
          :message => exception.backtrace.first,
          }
        end

        def render name, values={}
          template = File.read("#{APP_LIBS}/views/#{name.to_s}.haml")
          haml_engine = Haml::Engine.new(template)
          haml_engine.render(binding, values)
        end

      end

    end
  end
end
