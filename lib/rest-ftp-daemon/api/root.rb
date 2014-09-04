module RestFtpDaemon
  module API

    class Root < Grape::API
      include RestFtpDaemon::API::Defaults
      logger ActiveSupport::Logger.new APP_LOGTO, 'daily'
      #add_swagger_documentation

      mount RestFtpDaemon::API::Jobs => '/jobs'



      helpers do
        def info message, level = 0
          Root.logger.add(Logger::INFO, "#{'  '*level} #{message}", "API::Root")
        end

        def job_list_by_status
          statuses = {}
          alljobs = $threads.list.map do |thread|
            job = thread[:job]
            next unless job.is_a? Job
            statuses[job.get_status] ||= 0
            statuses[job.get_status] +=1
          end

          statuses
        end
      end

      ######################################################################
      ####### INIT
      ######################################################################
      def initialize
        # Setup logger
        #@@logger = Logger.new(APP_LOGTO, 'daily')
        # @@queue = Queue.new

        # Create new thread group
        $threads = ThreadGroup.new

        # Other stuff
        $last_worker_id = 0
        #info "initialized"
        super
      end


      ######################################################################
      ####### API DEFINITION
      ######################################################################

      # Server global status
      get '/' do
        #info "GET /"
        info "GET /"

        status 200
        {
          name: RestFtpDaemon::NAME,
          hostname: `hostname`.chomp,
          version: RestFtpDaemon::VERSION,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          status: job_list_by_status,
          routes: RestFtpDaemon::API::Root::routes
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
