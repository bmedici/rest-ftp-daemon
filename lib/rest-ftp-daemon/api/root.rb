require "grape"
require 'grape-swagger'
# require 'grape-swagger/entity'
# require 'grape-swagger/representable'

module RestFtpDaemon
  module API
    class Root < Grape::API
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
      include BmcDaemonLib::LoggerHelper


      ### LOGGING & HELPERS
      logger  BmcDaemonLib::LoggerPool.instance.get :core
      helpers RestFtpDaemon::CommonHelpers
      helpers RestFtpDaemon::ApiHelpers
      helpers BmcDaemonLib::LoggerHelper

      helpers do

        include BmcDaemonLib::LoggerHelper

        def logger
          Root.logger
        end

        def exception_error error, http_code, exception, message = nil
          # Extract message lines
          lines = exception.message.lines

          # Log error to file
          log_error "[#{error}] [#{http_code}] #{lines.shift} ", lines

          # Default to exeption message if empty
          message ||= exception.message

          # Send it to rollbar
          Rollbar.error exception, "api: #{exception.class.name}: #{exception.message}"

          # Return error
          error!({
            code: error,
            message: message,
            exception: exception.class.name,
            http_code: http_code,
          }, http_code)
        end

      end

      before do
        log_request
      end


      ## EXCEPTION HANDLERS
      rescue_from Grape::Exceptions::InvalidMessageBody do |exception|
        exception_error :api_invalid_message_body, 400, exception, "Bad request: message body does not match declared format, check command syntax (#{exception.message})"
      end
      rescue_from RestFtpDaemon::LocationSchemeUnsupported do |exception|
        exception_error :unsupported_scheme, 422, exception, "Bad request: unsupported scheme (#{exception.message})"
      end
      rescue_from RestFtpDaemon::LocationParseError do |exception|
        exception_error :location_parse_error, 422, exception, "Bad request: location parse error (#{exception.message})"
      end
      rescue_from RestFtpDaemon::JobUnknownTransform do |exception|
        exception_error :location_parse_error, 422, exception, "Bad request: unknow transform (#{exception.message})"
      end
      rescue_from :all do |exception|
        # puts exception.backtrace.join("\n")
        exception_error :api_error, 500, exception, exception.message
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
          },
        tags: [
            { name: 'jobs', description: 'Job management' },
            { name: 'status', description: 'Daemon status and configuration' }
          ]

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