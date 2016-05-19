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

      mount RestFtpDaemon::API::Jobs => MOUNT_JOBS
      mount RestFtpDaemon::API::Dashbaord => MOUNT_BOARD


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


      ### SHOW STATUS

      desc "Show daemon status"
      get "/status" do
        mem = GetProcessMem.new
        status 200
        return  {
          hostname: `hostname`.to_s.chomp,
          version: APP_VER,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          counters: $queue.counters,
          memory_bytes: mem.bytes.to_i,
          memory_mb: mem.mb.round(0),
          status: $queue.counts_by_status,
          workers: $pool.worker_variables,
          jobs_count: $queue.jobs_count,
          jobs_queued: $queue.queued_ids,
          }
      end


      ### SHOW CONFIG

      desc "Show daemon config"
      get "/config" do
        status 200
        return Helpers.get_censored_config
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


      ### RELOAD CONFIG

      desc "Reload daemon config"
      post "/config/reload" do
        if Settings.at(:debug, :allow_reload)==true
          Settings.reload!
          status 200
          return Helpers.get_censored_config
        else
          status 403
          return "Config reload not permitted"
        end
      end

    end
  end
end
