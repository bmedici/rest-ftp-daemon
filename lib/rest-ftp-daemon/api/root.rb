require "grape"
require "get_process_mem"

module RestFtpDaemon
  module API
    class Root < Grape::API


####### CLASS CONFIG

      helpers RestFtpDaemon::LoggerHelper

      logger RestFtpDaemon::LoggerPool.instance.get :api

      do_not_route_head!
      do_not_route_options!

      format :json

      mount RestFtpDaemon::API::Jobs => "/jobs"
      mount RestFtpDaemon::API::Dashbaord => "/"


####### INITIALIZATION

      def initialize
        # Call daddy
        super

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingQueue unless defined? $pool
      end


####### HELPERS

      helpers do

        def logger
          Root.logger
        end

      end


####### GET /routes

      desc "show application routes"
      get "/routes" do
        log_info "GET /routes"
        status 200
        return RestFtpDaemon::API::Root.routes
      end


####### GET /status

      # Server global status
      get "/status" do
        log_info "GET /status"
        mem = GetProcessMem.new

        status 200
        return  {
          hostname: `hostname`.chomp,
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
          config: Helpers.get_censored_config
          }
      end


    end
  end
end
