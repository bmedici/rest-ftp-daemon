require 'haml'
require "facter"
require "sys/cpu"


module RestFtpDaemon
  module API

    class Root < Grape::API


####### CLASS CONFIG

      logger RestFtpDaemon::Logger.new(:api, "API")

      do_not_route_head!
      do_not_route_options!

      # FIXME
      # add_swagger_documentation
      # default_error_formatter :json
      format :json


####### EXCETPIONS HANDLING
      # FIXME
      # rescue_from :all do |e|
      #   error_response(message: "Internal server error", status: 500)
      # end


####### HELPERS

      helpers do

        def info message, level = 0
          Root.logger.info(message, level)
        end

        def api_error exception
          {
          :error => exception.message,
          :message => exception.backtrace.first,
          #:backtrace => exception.backtrace,
          }
        end

        def render name, values={}
          template = File.read("#{APP_LIBS}/views/#{name.to_s}.haml")
          haml_engine = Haml::Engine.new(template)
          haml_engine.render(binding, values)
        end

        def job_find job_id
          return nil if ($queue.all_size==0)

          # Find a job with exactly this id, or prefixed if not found
          $queue.find_by_id(job_id) || $queue.find_by_id(job_id, true)
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
        popped_jobs = $queue.ordered_popped.reverse
        @jobs_queued = $queue.ordered_queue.reverse

        if params["only"].nil? || params["only"].blank?
          @only = nil
        else
          @only = params["only"].to_sym
        end

        if @only.nil?
          @jobs_popped = popped_jobs
        else
          @jobs_popped = $queue.popped_reverse_sorted_by_status @only
        end

        # Count jobs for each status
        @counts = $queue.popped_counts_by_status

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


    end
  end
end
