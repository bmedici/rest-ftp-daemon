require "grape"

module RestFtpDaemon
  module API
    class Root < Grape::API
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      ### LOGGING & HELPERS
      helpers RestFtpDaemon::CommonHelpers
      helpers RestFtpDaemon::ApiHelpers
      helpers BmcDaemonLib::LoggerHelper

      helpers do
        def log_prefix
          ['API', nil, nil]
        end

        def logger
          Root.logger
        end
      end

      before do
        log_request
      end

      ### CLASS CONFIG
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
