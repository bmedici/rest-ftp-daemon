require "grape"

module RestFtpDaemon
  module API
    class Root < Grape::API
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation



      ### LOGGING & HELPERS
      helpers do
        def log_prefix
          ['API', nil, nil]
        end

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
          log_info       "HTTP #{request_method} #{request_uri}", params
        end
      end

      before do
        log_request
      end

      ### CLASS CONFIG
      helpers BmcDaemonLib::LoggerHelper
      logger BmcDaemonLib::LoggerPool.instance.get :api
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
        super

        # Check that Queue and Pool are available
        unless $pool.is_a? RestFtpDaemon::WorkerPool
          log_error "Metrics.sample: invalid WorkerPool"
          raise RestFtpDaemon::MissingPool
        end
        unless $queue.is_a? RestFtpDaemon::JobQueue
          log_error "Metrics.sample: invalid JobQueue"
          raise RestFtpDaemon::MissingQueue
        end
      end


      ### ENDPOINTS
      get "/" do
        redirect dashboard_url()
      end

    end
  end
end
