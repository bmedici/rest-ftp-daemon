require "grape"
require 'grape-swagger'
# require 'grape-swagger/entity'
# require 'grape-swagger/representable'

module RestFtpDaemon
  module API
    class Root < Grape::API
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      include BmcDaemonLib

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

      # Response formats
      content_type :json, 'application/json; charset=utf-8'
      # format :json
      default_format :json

      # Pretty JSON
      formatter :json_tmp, ->(object, env) do
        put "----- formatter"
        puts object.inspect
        # JSON.pretty_generate(JSON.parse(object.to_json))
        #if object.respond_to? to_hash
          JSON.pretty_generate(object)
        #end
        put "-----"
      end


      ### MOUNTPOINTS
      mount RestFtpDaemon::API::Status      => MOUNT_STATUS
      mount RestFtpDaemon::API::Jobs        => MOUNT_JOBS
      mount RestFtpDaemon::API::Dashbaord   => MOUNT_BOARD
      mount RestFtpDaemon::API::Config      => MOUNT_CONFIG
      mount RestFtpDaemon::API::Debug       => MOUNT_DEBUG


      ### API Documentation
      add_swagger_documentation hide_documentation_path: true,
        api_version: Conf.app_ver,
        doc_version: Conf.app_ver,
        mount_path: MOUNT_SWAGGER_JSON,
        info: {
          title: Conf.app_name,
          version: Conf.app_ver,
          description: "API description for #{Conf.app_name} #{Conf.app_ver}",
          }



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
