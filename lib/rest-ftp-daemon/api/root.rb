module RestFtpDaemon
  module API

    class Root < Grape::API
      include RestFtpDaemon::API::Defaults
      logger ActiveSupport::Logger.new APP_LOGTO, 'daily'
      #add_swagger_documentation

      # add_swagger_documentation base_path: "/api",
      #                           api_version: 'v1',
      #                           hide_documentation_path: false


      mount RestFtpDaemon::API::Jobs => '/jobs'
      # mount RestFtpDaemon::API::Debug => '/debug'
      #group( :debug ) { mount RestFtpDaemon::API::Debug }

      helpers do
        def info message, level = 0
          Root.logger.add(Logger::INFO, "#{'  '*level} #{message}", "API::Root")
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
          app_name: APP_NAME,
          hostname: `hostname`.chomp,
          version: RestFtpDaemon::VERSION,
          started: APP_STARTED,
          uptime: (Time.now - APP_STARTED).round(1),
          jobs_count: $threads.list.size,
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
