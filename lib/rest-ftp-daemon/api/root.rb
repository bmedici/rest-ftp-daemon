require "grape"
require "get_process_mem"

module RestFtpDaemon
  module API
    class Root < Grape::API

      ### CLASS CONFIG

      helpers RestFtpDaemon::LoggerHelper
      logger RestFtpDaemon::LoggerPool.instance.get :api

      do_not_route_head!
      do_not_route_options!

      format :json
      content_type :json, 'application/json; charset=utf-8'

      mount RestFtpDaemon::API::Jobs => "/jobs"
      mount RestFtpDaemon::API::Dashbaord => "/"


      ### INITIALIZATION

      def initialize
        # Call daddy
        super

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingPool unless defined? $pool
      end


      ### HELPERS

      helpers do
        def logger
          Root.logger
        end
      end


      ### Common request logging

      before do
        log_info "HTTP #{request.request_method} #{request.fullpath}", params
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
