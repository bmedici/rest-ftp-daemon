require "grape"
require 'grape-swagger'
# require 'grape-swagger/entity'
# require 'grape-swagger/representable'

module RestFtpDaemon
  module API
    class Root < Grape::API
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      #include BmcDaemonLib
      include BmcDaemonLib::LoggerHelper


      ### LOGGING & HELPERS
      logger  BmcDaemonLib::LoggerPool.instance.get :api
      helpers RestFtpDaemon::CommonHelpers
      helpers RestFtpDaemon::ApiHelpers
      helpers BmcDaemonLib::LoggerHelper

      helpers do

        include BmcDaemonLib::LoggerHelper

        def log_context
          {caller: "API::Root"}
        end

        def logger
          Root.logger
        end

        def exception_error error, http_code, exception
          # Extract message lines
          lines = exception.message.lines
            #.lines.collect(&:strip).reject(&:empty?)

          # Log error to file
          log_error "[#{error}] [#{http_code}] #{lines.shift} ", lines

          # Return error
          error!({
            error: error,
            http_code: http_code,
            class: exception.class.name,
            message: exception.message,
          }, http_code)
        end

      end

      before do
        log_request
      end


      ## EXCEPTION HANDLERS
      rescue_from :all do |exception|
        Rollbar.error exception, "api: #{exception.class.name}: #{exception.message}"
        # Rollbar.error exception, "api [#{error}]: #{exception.class.name}: #{exception.message}"
        #error!({error: :internal_server_error, message: exception.message}, 500)
        exception_error :api_error, 500, exception
      end


      ### CLASS CONFIG
      do_not_route_head!
      do_not_route_options!
      # version 'v1'

      # Response formats
      #content_type :json, 'application/json; charset=utf-8'
      format :json
      # default_format :json

      # Pretty JSON
      # formatter :json_tmp, ->(object, env) do
      #   puts object.inspect
      #   JSON.pretty_generate(object)
      # end

      ### MOUNTPOINTS
      mount API::Status      => MOUNT_STATUS
      mount API::Jobs        => MOUNT_JOBS
      mount API::Dashboard   => MOUNT_BOARD
      mount API::Config      => MOUNT_CONFIG
      mount API::Debug       => MOUNT_DEBUG


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