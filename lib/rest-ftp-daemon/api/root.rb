require 'haml'
require "facter"
require "sys/cpu"


module RestFtpDaemon
  module API

    class Root < Grape::API


####### CLASS CONFIG
      include RestFtpDaemon::API::Defaults
      logger ActiveSupport::Logger.new(Settings.logs.api, 'daily') unless Settings.logs.api.nil?
      #add_swagger_documentation

      mount RestFtpDaemon::API::Jobs => '/jobs'
      # mount RestFtpDaemon::API::Workers => '/workers'


####### HELPERS

      helpers do
        def info message, level = 0
          Root.logger.add(Logger::INFO, "#{'  '*level} #{message}", "API::Root")
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
        $last_worker_id = 0

        # Check that Queue and Pool are available
        raise RestFtpDaemon::MissingQueue unless defined? $queue
        raise RestFtpDaemon::MissingQueue unless defined? $pool

        super
      end


####### API DEFINITION

      # Server global status
      get '/' do
        # Prepare data
        @jobs_all = $queue.all
        #@jobs_all_size = $queue.all_size
        #@jobs_all = $queue.all_size

        # Initialize UsageWatch
        Facter.loadfacts
        @info_load = Sys::CPU.load_avg.first.to_f
        @info_procs = (Facter.value :processorcount).to_i
        @info_ipaddr = Facter.value(:ipaddress)
        @info_memfree = Facter.value(:memoryfree)


        # Compute normalized load
        # puts "info_procs: #{info_procs}"
        if @info_procs.zero?
          @info_norm = "N/A"
        else
          @info_norm = (100 * @info_load / @info_procs).round(1)
        end

        # Compute total transferred
        @total_transferred = 0
        @jobs_all.each do |job|
          sent = job.get(:file_sent)
          @total_transferred += sent unless sent.nil?
        end

        # Compile haml template
        @name = "Test"
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
        info "GET /"
        status 200
        return  {
          hostname: `hostname`.chomp,
          version: Settings.app_ver,
          config: Settings.to_hash,
          started: Settings.app_started,
          uptime: (Time.now - Settings.app_started).round(1),
          status: job_list_by_status,
          queue_size: $queue.all_size,
          jobs_queued: $queue.queued.collect(&:id),
          jobs_popped: $queue.popped.collect(&:id),
          routes: RestFtpDaemon::API::Root::routes,
          }
      end

      # Server test
      get '/debug' do
        info "GET /debug/"
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
