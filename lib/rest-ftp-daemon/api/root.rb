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

        def info message, context = {}
          Root.logger.info_with_id message, context
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

        def job_find job_id
          return nil if ($queue.all_size==0)

          # Find a job with exactly this id, or prefixed if not found
          $queue.find_by_id(job_id) || $queue.find_by_id(job_id, true)
        end

      end

    end
  end
end
