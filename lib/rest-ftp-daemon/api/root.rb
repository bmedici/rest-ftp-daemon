module RestFtpDaemon
  module API
    class Root < Grape::API

      ### LOGGING & HELPERS

      helpers do
        def logger
          Root.logger
        end

        def log_request
          if env.nil?
            puts "HTTP_ENV_IS_NIL: #{env.inspect}"
            return
          end

          request_method = env['REQUEST_METHOD']
          request_path   = env['REQUEST_PATH']
          request_uri    = env['REQUEST_URI']
          log_info "HTTP #{request_method} #{request_uri}", params
        end
      end

      before do
        log_request
      end


      ### CLASS CONFIG

      helpers RestFtpDaemon::LoggerHelper
      logger RestFtpDaemon::LoggerPool.instance.get :api
      do_not_route_head!
      do_not_route_options!
      # version 'v1'
      format :json
      content_type :json, 'application/json; charset=utf-8'


      ### MOUNTPOINTS

      mount RestFtpDaemon::API::Status => MOUNT_STATUS
      mount RestFtpDaemon::API::Jobs => MOUNT_JOBS
      mount RestFtpDaemon::API::Dashbaord => MOUNT_BOARD
      mount RestFtpDaemon::API::Config => MOUNT_CONFIG
      mount RestFtpDaemon::API::Debug => MOUNT_DEBUG


      ### INITIALIZATION

      def initialize
        # Call daddy
        super

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingPool unless defined? $pool
      end


      ### ROOT URL ACCESS

      get "/" do
        redirect Helpers.dashboard_filter_url()
      end

    end
  end
end
