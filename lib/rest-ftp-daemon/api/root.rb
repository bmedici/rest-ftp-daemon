require "get_process_mem"

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

      format :json
      content_type :json, 'application/json; charset=utf-8'

      mount RestFtpDaemon::API::Status => MOUNT_STATUS
      mount RestFtpDaemon::API::Jobs => MOUNT_JOBS
      mount RestFtpDaemon::API::Dashbaord => MOUNT_BOARD
      mount RestFtpDaemon::API::Config => MOUNT_CONFIG


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


      ### SHOW ROUTES

      desc "Show application routes"
      get "/routes" do
        status 200
        return RestFtpDaemon::API::Root.routes
      end


      desc "List all Jobs params encodings"
      get "/encodings" do
        # Get jobs to display
        encodings = {}
        jobs = $queue.jobs

        jobs.each do |job|
          # here = out[job.id] = {}
          me = encodings[job.id] = {}

          me[:error] = job.error.encoding.to_s unless job.error.nil?
          me[:status] = job.status.encoding.to_s unless job.status.nil?

          Job::FIELDS.each do |name|
            value = job.send(name)
            me[name] = value.encoding.to_s if value.is_a? String
          end

          job.infos.each do |name, value|
            me["infos_#{name}"] = value.encoding.to_s if value.is_a? String
          end

          # # Computed fields
          # expose :age
          # expose :exectime
        end

        encodings
      end

    end
  end
end
