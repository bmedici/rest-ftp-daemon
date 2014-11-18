require 'haml'
require "facter"
require "sys/cpu"


module RestFtpDaemon
  module API

    class Root < Grape::API


####### CLASS CONFIG

      include RestFtpDaemon::API::Defaults
      logger RestFtpDaemon::Logger.new(:api, "API")
      mount RestFtpDaemon::API::Jobs => '/jobs'
      #add_swagger_documentation
      # mount RestFtpDaemon::API::Workers => '/workers'


####### HELPERS

      helpers do
        def info message, level = 0
          Root.logger.info(message, level)
        end

        def job_list_by_status
          statuses = {}
          alljobs = $queue.all.map do |item|
            next unless item.is_a? Job
            statuses[item.get_status] ||= 0
            statuses[item.get_status] +=1
          end
          statuses
        end

      end


####### INITIALIZATION

      def initialize
        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingQueue unless defined? $pool
        super
      end


####### API DEFINITION

      # Server global status
      get '/' do
        info "GET /"

        # Initialize UsageWatch
        Facter.loadfacts
        @info_load = Sys::CPU.load_avg.first.to_f
        @info_procs = (Facter.value :processorcount).to_i
        @info_ipaddr = Facter.value(:ipaddress)
        @info_memfree = Facter.value(:memoryfree)

        # Compute normalized load
        if @info_procs.zero?
          @info_norm = "N/A"
        else
          @info_norm = (100 * @info_load / @info_procs).round(1)
        end

        # Jobs to display
        all_jobs_in_queue = $queue.all

        if params["only"].nil? || params["only"].blank?
          @only = nil
        else
          @only = params["only"].to_sym
        end

        case @only
        when nil
          @jobs = all_jobs_in_queue
        when :queue
          @jobs = $queue.queued
        else
          @jobs = $queue.by_status (@only)
        end

        # Count jobs for each status
        @counts = {}
        grouped = all_jobs_in_queue.group_by { |job| job.get(:status) }
        grouped.each do |status, jobs|
          @counts[status] = jobs.size
        end

        # Get workers status
        @gworker_statuses = $pool.get_worker_statuses

        # Compile haml template
        output = render :dashboard

        # Send response
        env['api.format'] = :html
        format "html"
        status 200
        content_type "text/html"
        body output

      end

      # Server global status
      get '/status' do
        info "GET /status"
        status 200
        return  {
          hostname: `hostname`.chomp,
          version: APP_VER,
          config: Settings.to_hash,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          counters: $queue.counters,
          status: job_list_by_status,
          queue_size: $queue.all_size,
          jobs_queued: $queue.queued.collect(&:id),
          jobs_popped: $queue.popped.collect(&:id),
          routes: RestFtpDaemon::API::Root::routes,
          }
      end

      # Server test
      get '/debug' do
        info "GET /debug"

        begin
          raise RestFtpDaemon::DummyException
        rescue RestFtpDaemon::RestFtpDaemonException => exception
          status 501
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 200
          {}
        end
      end

    end
  end
end
