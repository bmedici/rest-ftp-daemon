module RestFtpDaemon
  module API

    class Root < Grape::API
      include RestFtpDaemon::API::Defaults
      logger ActiveSupport::Logger.new Settings.logs.api, 'daily' unless Settings.logs.api.nil?
      #add_swagger_documentation

      mount RestFtpDaemon::API::Jobs => '/jobs'
      # mount RestFtpDaemon::API::Workers => '/workers'

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

      ######################################################################
      ####### INIT
      ######################################################################
      def initialize
        $last_worker_id = 0
        super
      end


      ######################################################################
      ####### API DEFINITION
      ######################################################################

      # Server global status
      get '/' do
        info "GET /"
        status 200
        return  {
          hostname: `hostname`.chomp,
          version: Settings.version,
          config: Settings.to_hash,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
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
