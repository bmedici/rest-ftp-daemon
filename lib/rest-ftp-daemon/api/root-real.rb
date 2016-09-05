require "grape"
require 'grape-swagger'

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


desc 'API Root'

      ### MOUNTPOINTS
      # mount RestFtpDaemon::API::Status      => MOUNT_STATUS
      # mount RestFtpDaemon::API::Jobs        => MOUNT_JOBS
      # mount RestFtpDaemon::API::Dashbaord   => MOUNT_BOARD
      # mount RestFtpDaemon::API::Config      => MOUNT_CONFIG
      # mount RestFtpDaemon::API::Debug       => MOUNT_DEBUG


      ### API Documentation
      add_swagger_documentation hide_documentation_path: true,
        api_version: BmcDaemonLib::Conf.app_ver,
        doc_version: BmcDaemonLib::Conf.app_ver,
        mount_path: MOUNT_SWAGGER_JSON,
        info: {
          title: BmcDaemonLib::Conf.app_name,
          version: BmcDaemonLib::Conf.app_ver,
          description: "API description for #{BmcDaemonLib::Conf.app_name} #{BmcDaemonLib::Conf.app_ver}",
          }
         # models: [
         #   RestFtpDaemon::Entities::Job,
         # ]

      ### GLOBAL EXCEPTION HANDLING
      # rescue_from :all do |e|
      #   raise e
      #   error_response(message: "Internal server error: #{e}", status: 500)
      # end


      ### INITIALIZATION
      def initialize
        super
      end

      ### ENDPOINTS
      get "/" do
        redirect dashboard_url()
      end

    end
  end
end
